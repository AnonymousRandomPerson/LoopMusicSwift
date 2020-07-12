#import "LoopFinderAuto.h"

/// Methods for using signal differencing results and signal spectra to find loop point candidates and relevant metrics for ranking.
@interface LoopFinderAuto (analysis)

/*!
 * Selects at most the n smallest values in an array, suppressing values that are too similar in position/index (based on LoopFinderAuto.minTimeDiff, indices are representative of frames). If not enough are found, the function returns just the minima that it does find.
 * @param array An array to be minimized over.
 * @param arraySize Array size.
 * @param n The number of minima to be searched for.
 * @return Output dictionary of arrays of minimum values ("values") and their corresponding indices ("indices"). Each array will have at most n elements.
 */
- (NSDictionary *)spacedMinima:(float *)array :(vDSP_Length)arraySize :(vDSP_Length)n;

/*!
 * Infers the loop region based on the distribution of spectrum MSEs throughout spectrogram windows.
 * @param specMSEs Vector of spectrum MSEs from the spectrogram differencing.
 * @param nWindows length of the specMSEs vector.
 * @param effectiveWindowDurations The effective (overlap-adjusted) window duration (in seconds) for each specMSE element.
 * @return Output dictionary with inferred sample numbers of the start and end of the loop region ("start" and "end"), as well as the ceiling MSE value that defines the region ("cutoff").
 */
- (NSDictionary *)inferLoopRegion:(float *)specMSEs :(vDSP_Length)nWindows :(float *)effectiveWindowDurations;

/*!
 * Calculates the "match length" metric based on spectrum MSEs and a cutoff. Represents roughly how long the two tracks match each other for.
 * @param specMSEs Vector of spectrum MSEs from spectrogram differencing.
 * @param nWindows The number of elements in specMSEs.
 * @param effectiveWindowDurations The effective (overlap-adjusted) window duration (in seconds) for each specMSE element.
 * @param cutoff The cutoff to use in calculation.
 * @return The match length value, in seconds.
*/
- (float)calcMatchLength:(float *)specMSEs :(vDSP_Length)nWindows :(float *)effectiveWindowDurations :(float)cutoff;

/*!
 * Calculates the "mismatch length" metric based on spectrum MSEs, and the loop region boundaries/cutoff. Represents roughly how long the two tracks DON'T match each other for outside the interval.
 * @param specMSEs Vector of spectrum MSEs from spectrogram differencing.
 * @param nWindows The number of elements in specMSEs.
 * @param regionStart The index in specMSEs where the region starts.
 * @param regionEnd The index in specMSEs where the region ends.
 * @param effectiveWindowDurations The effective (overlap-adjusted) window duration (in seconds) for each specMSE element.
 * @param cutoff The cutoff to be used in calculation.
 * @return The mismatch length value, in seconds.
 */
- (float)calcMismatchLength:(float *)specMSEs :(vDSP_Length)nWindows :(vDSP_Length)regionStart :(vDSP_Length)regionEnd :(float *)effectiveWindowDurations :(float)cutoff;

/*!
 * Refines the loop lag value using the loop region estimate.
 * @param audio The audio signal.
 * @param lag The base loop lag value, in frames.
 * @param regionStartSample The starting sample number of the loop region.
 * @param regionEndSample The ending sample number of the loop region.
 * @return The refined lag value, in frames.
 */
- (UInt32)refineLag:(AudioDataFloat *)audio :(UInt32)lag :(UInt32)regionStartSample :(UInt32)regionEndSample;


/*!
 * Finds the (self.nBestPairs) best loop starting points out of given candidates, and the lag values to corresponding end points.
 * @param audio The audio signal.
 * @param lag The desired base lag value.
 * @param starts Vector of sample numbers of starting point candidates.
 * @param nStarts Number of starting point candidates.
 * @return An NSDictionary with the loop starting samples ("starts"), the lag values ("lags"), and the amplitude difference between the start and endpoints ("sampleDiffs").
 */
- (NSDictionary *)findEndpointPairs:(AudioDataFloat *)audio :(UInt32)lag :(vDSP_Length *)starts :(vDSP_Length)nStarts;

/*!
 * Finds the (self.nBestPairs) best loop starting points and the lag values to corresponding end points, based on spectrogram differencing and loop region inferencing results.
 * @param audio The audio signal.
 * @param lag The desired base lag value.
 * @param specMSEs Vector of the spectrum MSE values from spectrogram differencing.
 * @param nWindows Size of specMSEs.
 * @param startSamples The starting sample numbers of each window in specMSEs.
 * @param windowSizes The window sizes in specMSEs.
 * @param regionStart The index in specMSEs where the region starts.
 * @param regionEnd The index in specMSEs where the region ends.
 * @return An NSDictionary with the loop starting samples ("starts"), the lag values ("lags"), and the amplitude difference between the start and endpoints ("sampleDiffs").
 */
- (NSDictionary *)findEndpointPairsSpectra: (AudioDataFloat *)audio :(UInt32)lag :(float *)specMSEs :(UInt32)nWindows :(UInt32 *)startSamples :(UInt32 *)windowSizes :(vDSP_Length)regionStart :(vDSP_Length)regionEnd;


/*!
 * Runs biasedMeanSpectrumMSE with alpha = 0.1, i.e. averages the lower 90% of spectrum MSEs.
 * @param specMSEs Vector of spectrum MSEs from spectrogram differencing.
 * @param regionStart The index in specMSEs where the loop region starts.
 * @param regionEnd The index in specMSEs where the loop region ends.
  * @return The biased mean spectrum MSE value.
 */
- (float)biasedMeanSpectrumMSE: (float *)specMSEs :(vDSP_Length)regionStart :(vDSP_Length)regionEnd;
/*!
 * Calculates a biased mean spectrum MSE from spectrogram differencing, within a specified loop region. "Biased" in this context means excluding values above a specified alpha quantile.
 * @param specMSEs Vector of spectrum MSEs from spectrogram differencing.
 * @param regionStart The index in specMSEs where the loop region starts.
 * @param regionEnd The index in specMSEs where the loop region ends.
 * @param alpha The upper proportion of specMSEs to ignore in the mean calculation. Must be between 0 and 1.
 * @return The biased mean spectrum MSE value.
 */
- (float)biasedMeanSpectrumMSE: (float *)specMSEs :(vDSP_Length)regionStart :(vDSP_Length)regionEnd :(float)alpha;

@end
