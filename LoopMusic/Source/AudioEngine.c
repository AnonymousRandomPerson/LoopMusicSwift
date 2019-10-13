#include <stdio.h>
#import "AudioEngine.h"

/// The number of buffers used in rotation during audio playback.
#define NUM_BUFFERS 3
/// The size of each buffer used in audio playback.
#define BUFFER_SIZE 16384

/// All types of audio that are supported.
typedef enum _AudioType {INT32, INT16, FLOAT} AudioType;

/// The audio queue currently being used to play audio.
AudioQueueRef queue;
const AudioStreamBasicDescription *_Nonnull origAudioDesc;
AudioQueueBufferRef buffers[NUM_BUFFERS];

/// The index of the currently playing sample within the audio data.
int64_t sampleCounter;
/// The total number of samples in the audio data.
int64_t numSamples;
/// The currently loaded audio data to be fed into the audio buffer every update.
void *_Nonnull audioData;
/// The data type that the currently loaded audio audio is stored in.
AudioType audioType;

int64_t loopStart;
int64_t loopEnd;

/// Used to load audio buffer data from any type of stored audio.
#define loadBuffer(castedBufferData, castedAudioData) \
for (unsigned int i = 0; i < BUFFER_SIZE / sizeof(castedAudioData[0]); i++) { \
    if (sampleCounter >= numSamples) { \
        castedBufferData[i] = 0; \
    } else { \
        castedBufferData[i] = castedAudioData[sampleCounter++]; \
    } \
    if (loopEnd > 0 && sampleCounter > loopEnd) { \
        sampleCounter = loopStart; \
    } \
} \

/// Callback to load audio buffers with audio samples.
void audioCallback(void *customData, AudioQueueRef queue, AudioQueueBufferRef buffer) {
    void *bufferData = buffer->mAudioData;
    switch (audioType) {
        case INT32:
            loadBuffer(((int32_t*) bufferData), ((int32_t*) audioData))
            break;
        case INT16:
            loadBuffer(((int16_t*) bufferData), ((int16_t*) audioData))
            break;
        case FLOAT:
            loadBuffer(((float*) bufferData), ((float*) audioData))
            break;
    }
    
    AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
}

/// Loads audio data into the engine in preparation for audio playback.
OSStatus loadAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription *_Nonnull audioDesc) {
    if (origAudioDesc != NULL) {
        // Deallocate any existing audio buffers.
        for (unsigned int i = 0; i < NUM_BUFFERS; i++) {
            OSStatus status = AudioQueueFreeBuffer(queue, buffers[i]);
            if (status != 0) {
                return status;
            }
        }
    }
    
    origAudioDesc = audioDesc;
    OSStatus status = AudioQueueNewOutput(audioDesc, audioCallback, NULL, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &queue);
    if (status != 0) {
        return status;
    }
    
    audioData = newAudioData;
    numSamples = newNumSamples;
    
    // Initialize audio buffers according to the audio description.
    for (unsigned int i = 0; i < NUM_BUFFERS; i++) {
        OSStatus status = AudioQueueAllocateBuffer(queue, BUFFER_SIZE, &buffers[i]);
        if (status != 0) {
            return status;
        }
        buffers[i]->mAudioDataByteSize = BUFFER_SIZE;
    }
    return status;
}

OSStatus load32BitAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription *_Nonnull audioDesc) {
    audioType = INT32;
    return loadAudio(newAudioData, newNumSamples, audioDesc);
}

OSStatus load16BitAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription *_Nonnull audioDesc) {
    audioType = INT16;
    return loadAudio(newAudioData, newNumSamples, audioDesc);
}

OSStatus loadFloatAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription *_Nonnull audioDesc) {
    audioType = FLOAT;
    return loadAudio(newAudioData, newNumSamples, audioDesc);
}

void setLoopPoints(int64_t newLoopStart, int64_t newLoopEnd) {
    loopStart = newLoopStart * origAudioDesc->mChannelsPerFrame;
    loopEnd = newLoopEnd * origAudioDesc->mChannelsPerFrame;
}

OSStatus playAudio() {
    // Preload the first set of audio data.
    for (unsigned int i = 0; i < NUM_BUFFERS; i++) {
        audioCallback(NULL, queue, buffers[i]);
    }
    return AudioQueueStart(queue, NULL);
}

OSStatus stopAudio() {
    OSStatus status = AudioQueueStop(queue, true);
    if (status != 0) {
        return status;
    }
    sampleCounter = 0;
    return status;
}
