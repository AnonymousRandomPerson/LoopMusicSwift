#import "LoopFinderAuto.h"

// Top-level methods for synthesizing other methods from differencing, spectra, and analysis into a complete process.
@interface LoopFinderAuto (synthesis)

/*!
 * Calculates confidence levels given a collection of loss values. Calculations are based on the logistic/sigmoid function, and will always sum to 1, except in the special case of multiple loss values being zero with regularization of zero.
 * @param losses Array of nonnegative loss values.
 * @param regularization Nonnegative regularization value for losses.
 * @return Array of confidence values corresponding to the loss values. May be nan if all the loss values are very large.
 */
- (NSArray *)calcConfidence:(NSArray *)losses :(float)regularization;
/*!
 * Calculates confidence levels using self->confidenceRegularization.
 * @param losses Array of nonnegative loss values.
 * @return Array of confidence values corresponding to the loss values. May be nan if all the loss values are very large
 */
- (NSArray *)calcConfidence:(NSArray *)losses;


/*!
 * Performs spectral analysis on audio for a given lag value.
 * @param audio The audio data.
 * @param lag The lag value to analyze.
 * @return Dictionary containing analysis results. Has keys "startSamples", "refinedLags", "sampleDiffs", "spectrumMSE", "matchLength", "mismatchLength". "startSample", "refinedLags", and "sampleDiffs" have arrays of equal length, while "spectrumMSE", "matchLength", and "mismatchLength" are numeric values.
 */
- (NSDictionary *)analyzeLagValue:(AudioDataFloat *)audio :(UInt32)lag;



/*!
 * Finds loop points of an audio track, given no prior manual estimation.
 * @param audio 32-bit floating point stereo audio data.
 * @return Dictionary with keys "baseDurations", "startFrames", "endFrames", "confidences", "sampleDifferences".
 */
- (NSDictionary *)findLoopNoEst:(AudioDataFloat *)audio;

/*!
 * Finds loop points of an audio track, using prior estimation information (contained within class properties).
 * @param audio 32-bit floating point stereo audio data.
 * @return Dictionary with keys "baseDurations", "startFrames", "endFrames", "confidences", "sampleDifferences".
 */
- (NSDictionary *)findLoopWithEst:(AudioDataFloat *)audio;

@end
