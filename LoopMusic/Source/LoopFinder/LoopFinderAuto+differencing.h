#import "LoopFinderAuto.h"

/// Methods for differencing signals via sliding windows.
@interface LoopFinderAuto (differencing)
/*!
 * Performs a noise-weighted, sliding mean square error calculation on a stereo audio signal.
 * @param audio The audio signal in 32-bit floating point format.
 * @param result The array to store the result in. Should be at least the same length as the audio signal.
 */
- (void)audioAutoMSE:(AudioDataFloat *)audio :(float *)result;
/*!
 * Performs a noise-weighted, sliding mean square error calculation on a mono or stereo audio signal.
 * @param audio The audio signal in 32-bit floating point format.
 * @param useMono Flag for whether to use a mono or stereo signal.
 * @param result The array to store the result in. Should be at least the same length as the audio signal.
 */
- (void)audioAutoMSE:(AudioDataFloat *)audio :(bool)useMono :(float *)result;

/*!
 * Performs a noise-weighted, sliding mean square error calculation between two subranges in a stereo audio signal.
 * @param audio The audio signal in 32-bit floating point format.
 * @param startFirst The starting frame for the first subrange.
 * @param endFirst The ending frame for the first subrange.
 * @param startSecond The starting frame for the second subrange.
 * @param endSecond The ending frame for the second subrange.
 * @param result The array to store the result in. Should be at least (endFirst-startFirst+1) + (endSecond-startSecond+1) - 1 elements long.
 */
- (void)audioMSE:(AudioDataFloat *)audio :(UInt32)startFirst :(UInt32)endFirst :(UInt32)startSecond :(UInt32)endSecond :(float *)result;
/*!
 * Performs a noise-weighted, sliding mean square error calculation between two subranges in a mono or stereo audio signal.
 * @param audio The audio signal in 32-bit floating point format.
 * @param useMono Flag for whether to use a mono or stereo signal.
 * @param startFirst The starting frame for the first subrange.
 * @param endFirst The ending frame for the first subrange.
 * @param startSecond The starting frame for the second subrange.
 * @param endSecond The ending frame for the second subrange.
 * @param result The array to store the result in. Should be at least (endFirst-startFirst+1) + (endSecond-startSecond+1) - 1 elements long.
 */
- (void)audioMSE:(AudioDataFloat *)audio :(bool)useMono :(UInt32)startFirst :(UInt32)endFirst :(UInt32)startSecond :(UInt32)endSecond :(float *)result;

/*!
 * Performs a noise-weighted, sliding mean square error calculation on a signal with itself, and stores the values for nonnegative lag values.
 * @param x The signal vector.
 * @param n The length of the signal.
 * @param result The array to store the result in. Should be at least the same length as the signal.
 */
- (void)autoSlidingWeightedMSE:(float *)x :(vDSP_Length)n :(float *)result;
/*!
 * Performs a noise-weighted, sliding mean square error calculation between two signals.
 * @param a The first vector.
 * @param nA The length of the first signal.
 * @param b The second vector.
 * @param nB The length of the second signal.
 * @param result The array to store the result in. Should be at least of length nA+nB-1.
 */
- (void)slidingWeightedMSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result;
/*!
 * Performs a sliding sum of square errors calculation between two signals.
 * @param a The first vector.
 * @param nA The length of the first signal.
 * @param b The second vector.
 * @param nB The length of the second signal.
 * @param result The array to store the result in. Should be at least of length nA+nB-1.
 */
- (void)slidingSSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result;
/*!
 * Performs a cross-correlation calculation between two signals.
 * @param a The first vector.
 * @param nA The length of the first signal.
 * @param b The second vector.
 * @param nB The length of the second signal.
 * @param result The array to store the result in. Should be at least of length nA+nB-1.
 */
- (void)xcorr:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result;
@end
