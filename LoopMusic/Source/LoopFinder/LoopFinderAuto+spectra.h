#import "LoopFinderAuto.h"

/// Contains output data from the diffSpectrogram function.
typedef struct DiffSpectrogramInfo
{
    /// Array to the total MSE values for each window.
    float *mses;
    /// Number of windows in the spectrogram comparison.
    UInt32 nWindows;
    /// Array of the starting sample numbers of each window (in the primary, unlagged audio).
    UInt32 *startSamples;
    /// Array of the number of samples in each window.
    UInt32 *windowSizes;
    /// Array of the "effective duration" (in seconds) of each window, after correcting for window overlapping. Calculated by differencing the starting sample times. The last window has the same effective duration as its window duration.
    float *effectiveWindowDurations;
    
} DiffSpectrogramInfo;

/// Frees the contents of a DiffSpectrogramInfo structure. Does NOT free the parent structure itself.
void freeDiffSpectrogramInfo(DiffSpectrogramInfo *info);


/// Methods for calculating spectra and spectrograms of signals.
@interface LoopFinderAuto (spectra)

/*!
 * Performs in-place rectangular smoothing with radius 2 on a signal.
 * @param signal The signal vector.
 * @param n The length of the signal.
 */
- (void)smoothen:(float *)signal :(vDSP_Length)n;
/*!
 * Performs in-place rectangular smoothing with a given radius on a signal.
 * @param signal The signal vector.
 * @param n The length of the signal.
 * @param radius The desired radius to be used for the rectangular smoothing window. Must be a positive integer greater than 0.
 */
- (void)smoothen:(float *)signal :(vDSP_Length)n :(vDSP_Length)radius;

/*!
 * Calculates the power spectrum for a signal, up to a maximum frequency bin of 10 kHz.
 * @param signal The signal vector.
 * @param n The length of the signal.
 * @param spectrum Pointer to the spectrum array. Will be allocated in the function and should not be preallocated.
 * @param nBins Pointer to the number of bins in the output spectrum. Will be assigned in the function.
 */
- (void)calcSpectrum:(float *)signal :(vDSP_Length)n :(float **)spectrum :(vDSP_Length *)nBins;
/*!
 * Calculates the power spectrum for a signal, up to a specified maximum frequency bin.
 * @param signal The signal vector.
 * @param n The length of the signal.
 * @param spectrum Pointer to the spectrum array. Will be allocated in the function and should not be preallocated.
 * @param nBins Number of bins in the output spectrum. Will be assigned in the function.
 * @param fmax Value of the maximum frequency bin, in Hz.
 */
- (void)calcSpectrum:(float *)signal :(vDSP_Length)n :(float **)spectrum :(vDSP_Length *)nBins :(float)fmax;

/*!
 * Calculates the decibel MSE between two different power spectra of equal bin number.
 * @param a The first power spectrum (NOT in decibels).
 * @param b The second power spectrum (NOT in decibels).
 * @param n The length of a and b.
 * @param mse The MSE between the decibel-converted a and decibel-converted b.
 */
- (void)spectrumMSE:(float *)a :(float *)b :(vDSP_Length)n :(float *)mse;

/*!
 * Calculates window-wise MSEs between spectrograms of a signal with a lagged version of itself.
 * @param signal The audio signal in 32-bit floating point format.
 * @param lag The lag in frames between the primary and lagged signals.
 * @param results Pointer to the results of the spectrogram comparison, contained in a DiffSpectrogramInfo structure. Contents will be allocated within the function. The structure itself should be allocated before calling the function. Free the contents (not including the structure itself) by passing the pointer to freeDiffSpectrogramInfo().
 */
- (void)diffSpectrogram:(AudioDataFloat *)signal :(UInt32)lag :(DiffSpectrogramInfo *)results;

@end
