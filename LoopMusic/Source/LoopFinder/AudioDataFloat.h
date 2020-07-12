#ifndef AudioDataFloat_h
#define AudioDataFloat_h


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

#endif /* AudioDataFloat_h */
