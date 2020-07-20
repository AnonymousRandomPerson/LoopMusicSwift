#include <stdio.h>
#import "AudioEngine.h"

/// The number of buffers used in rotation during audio playback.
#define NUM_BUFFERS 3
/// The size of each buffer used in audio playback.
#define BUFFER_SIZE 16384

/// All types of audio that are supported.
typedef enum _AudioType {INT32, INT16, FLOAT} AudioType;

/// The currently loaded audio data to be fed into the audio buffer every update.
void *_Nonnull audioData;
/// The index of the currently playing sample within the audio data.
int64_t sampleCounter;
/// The total number of samples in the audio data.
int64_t numSamples;
/// The audio sample to start the loop at.
int64_t loopStart;
/// The audio sample to end the loop at.
int64_t loopEnd;
/// The data type that the currently loaded audio is stored in.
AudioType audioType;

/// The audio queue currently being used to play audio.
AudioQueueRef queue;
AudioStreamBasicDescription origAudioDesc;
AudioQueueBufferRef buffers[NUM_BUFFERS];

/// True if audio is currently playing.
bool playing = false;

/// True if the audio is currently paused (but not stopped).
bool paused = false;

/// Sample counter at the time of an active pause. Will be -1 if inapplicable.
int64_t sampleCounterOnPause;

/// True if loop times are used to loop playback.
bool loopPlayback = true;

double volumeMultiplier;

bool areAudioDescsEqual(AudioStreamBasicDescription desc1, AudioStreamBasicDescription desc2);

/// Used to load audio buffer data from any type of stored audio.
#define loadBuffer(castedBufferData, castedAudioData) \
for (unsigned int i = 0; i < BUFFER_SIZE / sizeof(castedAudioData[0]); i++) { \
    if (sampleCounter >= numSamples) { \
        castedBufferData[i] = 0; \
    } else { \
        castedBufferData[i] = castedAudioData[sampleCounter++] * volumeMultiplier; \
    } \
    if ((loopEnd > 0 && sampleCounter >= loopEnd && loopPlayback) || sampleCounter >= numSamples) { \
        sampleCounter = loopPlayback ? loopStart : 0; \
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
OSStatus loadAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription audioDesc, AudioType newAudioType) {
    if (newAudioType == audioType && areAudioDescsEqual(audioDesc, origAudioDesc)) {
        // If audio format is the same, no need to recreate the audio queue.
        audioData = newAudioData;
        numSamples = newNumSamples;
        audioType = newAudioType;
        return 0;
    } else {
        if (queue != NULL) {
            // Deallocate any existing audio buffers.
            for (unsigned int i = 0; i < NUM_BUFFERS; i++) {
                OSStatus status = AudioQueueFreeBuffer(queue, buffers[i]);
                if (status != 0) {
                    return status;
                }
            }
        }
        
        OSStatus status = AudioQueueNewOutput(&audioDesc, audioCallback, NULL, NULL, NULL, 0, &queue);
        if (status != 0) {
            return status;
        }
        
        origAudioDesc = audioDesc;
        audioData = newAudioData;
        numSamples = newNumSamples;
        audioType = newAudioType;
        
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
}

OSStatus load32BitAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription audioDesc) {
    return loadAudio(newAudioData, newNumSamples, audioDesc, INT32);
}

OSStatus load16BitAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription audioDesc) {
    return loadAudio(newAudioData, newNumSamples, audioDesc, INT16);
}

OSStatus loadFloatAudio(void *_Nonnull newAudioData, int64_t newNumSamples, const AudioStreamBasicDescription audioDesc) {
    return loadAudio(newAudioData, newNumSamples, audioDesc, FLOAT);
}

void setSampleCounter(int64_t newSampleCounter) {
    sampleCounter = newSampleCounter * origAudioDesc.mChannelsPerFrame;
}

void setLoopPoints(int64_t newLoopStart, int64_t newLoopEnd) {
    loopStart = newLoopStart * origAudioDesc.mChannelsPerFrame;
    loopEnd = newLoopEnd * origAudioDesc.mChannelsPerFrame;
}

void setVolumeMultiplier(double newVolumeMultiplier) {
    volumeMultiplier = newVolumeMultiplier;
}

void setLoopPlayback(bool newLoopPlayback) {
    loopPlayback = newLoopPlayback;
}

OSStatus playAudio() {
    // Preload the first set of audio data either if the queue wasn't paused, or if the sample counter has changed since playback was paused.
    if (!paused || (paused && sampleCounter != sampleCounterOnPause)) {
        // If the latter condition was true, then stop playback first to flush the audio queue.
        if (paused) {
            // Record the sample counter before calling stop, since audioCallback can be called a few times while the audio queue stops.
            const int64_t preStopSampleCounter = sampleCounter;
            OSStatus status = AudioQueueStop(queue, true);
            if (status != 0) {
                return status;
            }
            // Now rollback the sample counter to be what it was before stopping.
            sampleCounter = preStopSampleCounter;
        }
        for (unsigned int i = 0; i < NUM_BUFFERS; i++) {
            audioCallback(NULL, queue, buffers[i]);
        }
    }
    playing = true;
    paused = false;
    sampleCounterOnPause = -1;
    return AudioQueueStart(queue, NULL);
}

OSStatus pauseAudio() {
    playing = false;
    paused = true;
    OSStatus status = AudioQueuePause(queue);
    if (status != 0) {
        return status;
    }
    // Need to record this after pausing since audioCallback can still be called for a bit until the audio actually pauses.
    sampleCounterOnPause = sampleCounter;
    return status;
}

OSStatus stopAudio() {
    playing = false;
    paused = false;
    sampleCounterOnPause = -1;
    OSStatus status = AudioQueueStop(queue, true);
    if (status != 0) {
        return status;
    }
    sampleCounter = 0;
    return status;
}

int64_t getSampleCounter(void) {
    return sampleCounter / origAudioDesc.mChannelsPerFrame;
}

int64_t getNumSamples(void) {
    return numSamples / origAudioDesc.mChannelsPerFrame;
}

int64_t getLoopStart(void) {
    return loopStart / origAudioDesc.mChannelsPerFrame;
}

int64_t getLoopEnd(void) {
    return loopEnd / origAudioDesc.mChannelsPerFrame;
}

bool getLoopPlayback(void) {
    return loopPlayback;
}

/// Checks if two audio stream descriptions are equal. Returns false if either description is null.
bool areAudioDescsEqual(AudioStreamBasicDescription desc1, AudioStreamBasicDescription desc2) {
    return desc1.mBitsPerChannel == desc2.mBitsPerChannel &&
        desc1.mBytesPerFrame == desc2.mBytesPerFrame &&
        desc1.mBytesPerPacket == desc2.mBytesPerPacket &&
        desc1.mChannelsPerFrame == desc2.mChannelsPerFrame &&
        desc1.mFormatFlags == desc2.mFormatFlags &&
        desc1.mFormatID == desc2.mFormatID &&
        desc1.mFramesPerPacket == desc2.mFramesPerPacket &&
        desc1.mReserved == desc2.mReserved &&
        desc1.mSampleRate == desc2.mSampleRate;
}
