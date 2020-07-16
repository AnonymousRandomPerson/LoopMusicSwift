#ifndef AudioEngine_h
#define AudioEngine_h

#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CFRunLoop.h>

/// Loads 32-bit audio samples and playback metadata into the player.
OSStatus load32BitAudio(void *_Nonnull, int64_t, AudioStreamBasicDescription);

/// Loads 16-bit audio samples and playback metadata into the player.
OSStatus load16BitAudio(void *_Nonnull, int64_t, AudioStreamBasicDescription);

/// Loads 32-bit float audio samples and playback metadata into the player.
OSStatus loadFloatAudio(void *_Nonnull, int64_t, AudioStreamBasicDescription);

/// Sets the index of the currently playing sample within the audio data.
void setSampleCounter(int64_t);

/// Sets the points where the track will start and end looping.
void setLoopPoints(int64_t, int64_t);

/// Sets the multiplier used to alter the volume of the track.
void setVolumeMultiplier(double);

/// Sets whether loop times are used to loop playback.
void setLoopPlayback(bool);

/// Starts playing the loaded audio.
OSStatus playAudio(void);

/// Pauses playback of the loaded audio.
OSStatus pauseAudio(void);

/// Stops playing the loaded audio.
OSStatus stopAudio(void);

/// Gets the index of the currently playing sample within the audio data.
int64_t getSampleCounter(void);

/// Gets the total number of samples in the audio data.
int64_t getNumSamples(void);

/// Gets the audio sample to start the loop at.
int64_t getLoopStart(void);

/// Gets the audio sample to end the loop at.
int64_t getLoopEnd(void);

#endif
