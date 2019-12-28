#ifndef AudioEngine_h
#define AudioEngine_h

#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CFRunLoop.h>

/// Loads 32-bit audio samples and playback metadata into the player.
OSStatus load32BitAudio(void *_Nonnull, int64_t, const AudioStreamBasicDescription*_Nonnull);

/// Loads 16-bit audio samples and playback metadata into the player.
OSStatus load16BitAudio(void *_Nonnull, int64_t, const AudioStreamBasicDescription*_Nonnull);

/// Loads 32-bit float audio samples and playback metadata into the player.
OSStatus loadFloatAudio(void *_Nonnull, int64_t, const AudioStreamBasicDescription*_Nonnull);

/// Sets the points where the track will start and end looping.
void setLoopPoints(int64_t, int64_t);

/// Sets the multiplier used to alter the volume of the track.
void setVolumeMultiplier(double);

/// Starts playing the loaded audio.
OSStatus playAudio(void);

/// Stops playing the loaded audio.
OSStatus stopAudio(void);

#endif
