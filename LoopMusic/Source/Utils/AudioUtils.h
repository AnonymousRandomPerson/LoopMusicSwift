#ifndef AudioUtils_h
#define AudioUtils_h

#import <math.h>
#import <CoreAudioTypes/CoreAudioTypes.h>
#import <Accelerate/Accelerate.h>

/// Reference power level used in decibel calculation.
extern const float DB_REFERENCE_POWER;

typedef enum AudioType { INT32, INT16, FLOAT } AudioType;

/// Contains data for an audio track.
typedef struct AudioData
{
    /// The sample data for the track.
    AudioBuffer audioBuffer;
    /// The data type of the audio in the buffer.
    int audioType;
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
 * @param audioFloat The input audio track.
 * @return The average volume of the track in decibels.
*/
float calcAvgVolume(const AudioDataFloat *audioFloat);

/*!
 * Converts audio data to a 32-bit floating point format between -1 and 1.
 * @param audio The input audio track in buffer format.
 * @param audioFloat On output, the audio track in floating point format.
 * @param framerateReductionFactor The factor by which to reduce the audio framerate during conversion.
*/
void audioFormatToFloatFormat(const AudioData *audio, AudioDataFloat *audioFloat, long framerateReductionFactor);

/*!
 * Computes the mono audio field of the input audio track from its stereo data.
 * @param audioFloat The input audio track, with existing stereo data in `channel1` and `channel2`. On output, the `mono` field will contain the mono audio data.
*/
void fillMonoSignalData(AudioDataFloat *audioFloat);

#endif /* AudioUtils_h */
