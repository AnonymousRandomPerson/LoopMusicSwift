#ifndef AudioData_h
#define AudioData_h

#import <CoreAudioTypes/CoreAudioTypes.h>

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

#endif /* AudioData_h */
