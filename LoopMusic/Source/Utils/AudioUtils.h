#ifndef AudioUtils_h
#define AudioUtils_h

#import <math.h>
#import <CoreAudioTypes/CoreAudioTypes.h>
#import <Accelerate/Accelerate.h>

/// Reference power level used in decibel calculation.
extern const float DB_REFERENCE_POWER;
extern const float DB_REFERENCE_LUFS;

/// Contains data for an audio track.
typedef struct AudioData
{
    /// The sample data for the track.
    AudioBuffer audioBuffer;
    /// Number of samples in the audio data.
    int numSamples;
    /// The sample rate of the track.
    double sampleRate;
} AudioData;

/// Contains 32-bit floating-point data for a stereo audio track, with sample values between -1 and 1.
typedef struct AudioDataFloat
{
    /// The number of relevant frames in the track.
    UInt32 numFrames;
    /// The first channel data for the track.
    float *channel0;
    /// The second channel data for the track.
    float *channel1;
    /// Mono signal data for the track.
    float *mono;
} AudioDataFloat;

/// Contains 32-bit floating-point data for calculating a track's loudness via libebur128
typedef struct AudioData_ebur128
{
    /// The number of channels in the audio.
    unsigned int numChannels;
    /// The framerate.
    unsigned long framerate;
    /// The number of relevant frames in the track.
    UInt32 numFrames;
    /// The interleaved channel data.
    float *data;
} AudioData_ebur128;

/*!
 * Converts a power value to a decibel level.
 * @param power The input power for which to calculate a decibel level.
 * @return The volume in decibels corresponding to the power value.
 */
float powToDB(float power);

/*!
 * Computes the average power value of an audio track.
 * @param audioFloat The input audio track.
 * @return The average power level of the track.
*/
float calcAvgPow(const AudioDataFloat *audioFloat);

/*!
 * Computes the average volume in decibels of an audio track.
 * @param audioFloat The input audio track in floating-point format.
 * @return The average volume of the track in decibels.
*/
float calcAvgVolume(const AudioDataFloat *audioFloat);

/*!
 * Computes the integrated loudness in LUFS of an audio track, in accordance with EBU R 128 (a.k.a. ITU-R BS.1770): https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-4-201510-I!!PDF-E.pdf
 * @param audio The input audio track in buffer format.
 * @param framerateReductionLimit The highest allowable framerate reduction factor before resorting to truncation.
 * @param lengthLimit The highest allowable number of frames.
 * @param loudness The average loudness of the track in decibels when represented in floating-point format (normalized between -1 and 1).
 * @return Return code. 0 on success, -1 on failure.
*/
int calcIntegratedLoudnessFromBufferFormat(const AudioData *audio, long framerateReductionLimit, long lengthLimit, double *loudness);

/*!
 * Calculates the absolute limit on frames based on specified parameters.
 * @param numFrames The original number of frames.
 * @param framerateReductionLimit The highest allowable framerate reduction factor before resorting to truncation.
 * @param lengthLimit The highest allowable number of frames.
 * @return The limit on number of frames (before framerate reduction).
*/
long calcFrameLimit(long numFrames, long framerateReductionLimit, long lengthLimit);

/*!
 * Calculates the optimal framerate reduction factor based on specified parameters.
 * @param framerateReductionFactor The specified framerate reduction factor. Will be respected if it obeys the length limit; otherwise it will be changed.
 * @param numFrames The original number of frames.
 * @param framerateReductionLimit The highest allowable framerate reduction factor before resorting to truncation.
 * @param lengthLimit The highest allowable number of frames.
 * @return The optimal framerate reduction factor.
*/
long calcFramerateReductionFactor(long framerateReductionFactor, long numFrames, long framerateReductionLimit, long lengthLimit);

/*!
 * Converts audio data to a 32-bit floating point format between -1 and 1.
 * @param audio The input audio track in buffer format.
 * @param audioFloat On output, the audio track in floating point format.
 * @param framerateReductionFactor The factor by which to reduce the audio framerate during conversion.
*/
void audioFormatToFloatFormat(const AudioData *audio, AudioDataFloat *audioFloat, long framerateReductionFactor);

/*!
 * Converts audio data to a 32-bit floating point format for loudness calculation by libebur128.
 * @param audio The input audio track in buffer format.
 * @param audioOut On output, the audio track in the format libebur128 expects.
 * @param framerateReductionFactor The factor by which to reduce the audio framerate during conversion.
*/
void prepareAudioForLoudnessCalc(const AudioData *audio, AudioData_ebur128 *audioOut, long framerateReductionFactor);

/*!
 * Computes the mono audio field of the input audio track from its stereo data.
 * @param audioFloat The input audio track, with existing stereo data in `channel1` and `channel2`. On output, the `mono` field will contain the mono audio data.
*/
void fillMonoSignalData(AudioDataFloat *audioFloat);

#endif /* AudioUtils_h */
