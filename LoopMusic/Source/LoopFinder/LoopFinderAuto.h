#import <Foundation/Foundation.h>
#import "AudioData.h"
#import "AudioDataFloat.h"
#import <Accelerate/Accelerate.h>

typedef enum loopModeValue { loopModeAuto, loopModeT1T2, loopModeT1Only, loopModeT2Only } loopModeValue;

typedef enum AudioType { INT32, INT16, FLOAT } AudioType;

/// Automatic loop finder for audio files.
@interface LoopFinderAuto : NSObject
{
    // INTERNAL VALUES
    /// The "first" frame of the audio file, for the purposes of loop finding.
    UInt32 firstFrame;
    /// The length of the entire analysis window, in frames, for the purposes of loop finding.
//    UInt32 nFrames;   // Could be smaller than the actual audio length due to things like fade truncation.
    
    /// Average volume of the entire audio file, in dB.
    float avgVol;
    /// After shifting the audio volume such that avgVol is equal to this value, comparisons between spectra will only factor in frequency bins where both bins have a volume greater than 0 dB.
    float dBLevel;
    /// Reference power level used in decibel calculation.
    float powRef;
    
    /// Regularization for noise level in noise-normalized cross-correlation calculation.
    float noiseRegularization;
    /// Regularization for confidence value calculation.
    float confidenceRegularization;
    
    // END INTERNAL VALUES
}

// PARAMETERS
/// The number of duration value candidates to return from loop finding.
@property(nonatomic) NSInteger nBestDurations;
/// The number of start-end frame pairs to return per lag value from loop finding.
@property(nonatomic) NSInteger nBestPairs;

/// Number of seconds from the sliding mean square difference calculation to ignore, counting from the first value.
@property(nonatomic) float leftIgnore;
/// Number of seconds from the sliding mean square difference calculation to ignore, counting from the last value.
@property(nonatomic) float rightIgnore;

/// Tolerance for sample difference between starting frame and ending frame for an acceptable loop point pair.
@property(nonatomic) float sampleDiffTol;
/// Minimum number of seconds of harmonic similarity needed for a pair to count as a loop.
@property(nonatomic) float minLoopLength;
/// Minimum time difference in seconds to be used for non-maximum suppression when selecting top lag values and top start-end pairs.
@property(nonatomic) float minTimeDiff;

/// FFT size for each window in spectrogram calculations. Must be a power of two.
@property(nonatomic) UInt32 fftLength;
/// Overlap percent for spectrogram windows.
@property(nonatomic) float overlapPercent;


/// Optional estimation of the starting time. -1 is a flag for nothing.
@property(nonatomic) float t1Estimate;
/// Optional estimation of the ending time. -1 is a flag for nothing.
@property(nonatomic) float t2Estimate;

/// Deviation from estimated duration value to allow.
@property(nonatomic) float tauRadius;
/// Deviation from estimated starting time to allow.
@property(nonatomic) float t1Radius;
/// Deviation from estimated ending time to allow.
@property(nonatomic) float t2Radius;

// Penalty magnitudes must be from 0 to 1 inclusive. 0 represents a rectangular weighting, where every value within the acceptable range is weighted equally for ranking. 1 represents absolute certainty in estimate, and deviation from the estimate will not be allowed. For values in between, deviation from estimate is penalized by a multiple that increases linearly with deviation. For higher penalty values, the line has a higher slope.
/// Penalty magnitude for deviation from estimated duration value.
@property(nonatomic) float tauPenalty;
/// Penalty magnitude for deviation from estimated start time.
@property(nonatomic) float t1Penalty;
/// Penalty magnitude for deviation from estimated end time.
@property(nonatomic) float t2Penalty;


/// Flag for whether or not to automatically detect and remove a possible ending fade in the input audio data.
@property(nonatomic) bool useFadeDetection;
/// Flag for using the mono audio signal in some places for speedup
@property(nonatomic) bool useMonoAudio;
/// Factor by which framerate is reduced for loop finding analysis.
@property(nonatomic) int framerateReductionFactor;
/// Actual framerate of the audio.
@property(nonatomic) float framerate;
/// Effective framerate within the loop finder, as a result of reducing the global FRAMERATE by some factor.
@property(nonatomic) float effectiveFramerate;
/// EMPIRICAL LIMIT TO REDUCED AUDIO DATA LENGTH. Reduce the audio to this length before running the algorithm.
@property(nonatomic) NSUInteger lengthLimit;
// Maximum the framerate will be reduced by.
@property(nonatomic) NSInteger framerateReductionLimit;

/// FFT setup object for vDSP. Note: this is a struct pointer (type alias for OpaqueFFTSetup *)
@property(nonatomic) FFTSetup fftSetup;
/// N used for the current FFT setup object.
@property(nonatomic) unsigned long nSetup;

// END PARAMETERS


- (float)sanitizeFloat: (float)inputValue :(float)minValue;
- (float)sanitizeFloat: (float)inputValue :(float)minValue :(float)maxValue;
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue;
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue :(NSInteger)maxValue;

- (void)setFramerateReductionLimitFloat:(float)framerateReductionLimit;
- (void)setLengthLimitFloat:(float)lengthLimit;

/*!
 * Checks to see if there is an estimate for t1.
 * @return true if there is an estimate, false otherwise.
 */
- (bool)hasT1Estimate;

/*!
 * Checks to see if there is an estimate for t2.
 * @return true if there is an estimate, false otherwise.
 */
- (bool)hasT2Estimate;

/*!
 * Returns the current loop mode for the looper: auto (no endpoint estimates), both endpoint estimates, just T1, or just T2.
 * @return The current loop mode.
 */
- (loopModeValue)loopMode;

/*!
 * Returns the sample number for the t1 estimate.
 * @return Sample number for t1.
 */
- (UInt32)s1Estimate;

/*!
 * Returns the sample number for the t2 estimate.
 * @return Sample number for t2.
 */
- (UInt32)s2Estimate;

/*!
 * Computes lower and upper bounds for tau based on all the estimation information.
 * @return 2-element array containing the lower and upper bounds for tau.
 */
- (NSArray *)tauLimits:(UInt32)numFrames;
/*!
 * Computes lower and upper bounds for t1 based on all the estimation information and the current track length.
 * @param numFrames The number of frames in the current audio track.
 * @return 2-element array containing the lower and upper bounds for t1.
 */
- (NSArray *)t1Limits:(UInt32)numFrames;
/*!
 * Computes lower and upper bounds for t2 based on all the estimation information and the current track length.
 * @param numFrames The number of frames in the current audio track.
 * @return 2-element array containing the lower and upper bounds for t2.
 */
- (NSArray *)t2Limits:(UInt32)numFrames;

/*!
 * Calculates the slope value for a deviation given its penalty value (for tau, t1, and t2 estimates).
 * @param penalty Penalty value for the variable in question.
 * @return Slope value per second deviation from estimate.
 */
- (float)slopeFromPenalty:(float)penalty;

///*!
// * Performs an inexpensive preliminary FFT setup for vDSP.
// * @param audio The AudioDataFloat to be analyzed.
// */
//- (void)performFFTSetup;
/*!
 * Performs preliminary FFT setup for vDSP.
 * @param audio The AudioDataFloat to be analyzed.
 */
- (void)performFFTSetup:(AudioDataFloat *)audio;
///*!
// * Destroys the FFT setup for vDSP.
// */
- (void)performFFTDestroy;


/*!
 * Calculates the next highest power of 2 greater than or equal to num.
 * @param num The reference number.
 * @return The next highest power of 2 greater than or equal to the reference number.
 */
- (UInt32)nextPow2:(UInt32)num;

/*!
 * Converts a power value to a decibel level.
 * @param power The input power for which to calculate a decibel level.
 * @return The power level in decibels.
 */
- (float)powToDB:(float)power;

/*!
 * Finds and ranks possible loop points given some audio data.
 * @param audio The audio data structure containing the audio samples.
 * @return An NSDictionary* containing: [(NSArray* of NSNumber*) "baseDurations" - base loop duration (lag) values in frames, (NSArray* of NSArray* of NSNumber*) "startFrames" - corresponding start frames for each base duration value, (NSArray* of NSArray* of NSNumber*) "endFrames" - corresponding end frames, (NSArray* of NSNumber*) "confidences" - confidence values for each base duration value, (NSArray* of NSArray* of NSNumber*) "sampleDifferences" - sample differences for each start-end pair].
 */
- (NSDictionary *)findLoop:(const struct AudioData *)audio;

/*!
 * Sets all parameters to default values.
 */
- (void)useDefaultParams;

@end
