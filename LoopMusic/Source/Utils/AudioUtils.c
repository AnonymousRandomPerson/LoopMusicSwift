#include "AudioUtils.h"
#include "ebur128.h"

const float DB_REFERENCE_POWER = 1e-12;
// LUFS of a mono-channel, 997 Hz sine wave with a power of DB_REFERENCE_POWER (amplitude = sqrt(2)*1e-6). According to the standard, a three-channel, 997 Hz sine wave at 0 dB FS (max amplitude) should have a loudness of exactly -3.01 LUFS, which means that a mono-channel signal should have a loudness of (-3.01 - 10*log10(3)) LUFS. With an amplitude multiplier of sqrt(2)*1e-6, this becomes (-3.01 - 120 + 10*log10(2/3)) = -124.77 LUFS. Note that since LUFS is a frequency-dependent measurement, this is sort of an arbitrary reference point, but it's low enough to be reasonable.
const float DB_REFERENCE_LUFS = -124.77;

// Internal helpers
long max(long a, long b) {
    return a > b ? a : b;
}
long min(long a, long b) {
    return a < b ? a : b;
}

float powToDB(float power)
{
    return 10 * log10(power / DB_REFERENCE_POWER);
}

float calcAvgPow(const AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float channel0meansquare = 0;
    float channel1meansquare = 0;
    vDSP_measqv(audioFloat->channel0, stride, &channel0meansquare, audioFloat->numFrames);
    vDSP_measqv(audioFloat->channel1, stride, &channel1meansquare, audioFloat->numFrames);
    return (channel0meansquare + channel1meansquare) / 2;
}

float calcAvgVolume(const AudioDataFloat *audioFloat)
{
    return powToDB(calcAvgPow(audioFloat));
}

// Returns 0 on success, -1 on failure.
int calcIntegratedLoudness(const AudioData_ebur128 *processedAudio, double *loudness)
{
    ebur128_state *state = ebur128_init(processedAudio->numChannels, processedAudio->framerate, EBUR128_MODE_I);
    if (!state)
    {
        return -1;
    }

    int rc = -1;
    if (ebur128_add_frames_float(state, processedAudio->data, processedAudio->numFrames) != EBUR128_SUCCESS)
    {
        goto out;
    }
    if (ebur128_loudness_global(state, loudness) != EBUR128_SUCCESS)
    {
        goto out;
    }
    rc = 0;
out:
    ebur128_destroy(&state);
    return rc;
}

int calcIntegratedLoudnessFromBufferFormat(const AudioData *audio, long numSamples, long framerateReductionLimit, long lengthLimit, double *loudness)
{
    if (numSamples > audio->numSamples) {
        return -1;
    }

    // Convert audio to 32-bit floating point audio, reducing framerate and truncating if necessary.
    AudioData_ebur128 processedAudio;
    processedAudio.numChannels = audio->audioBuffer.mNumberChannels;
    processedAudio.numFrames = calcFrameLimit(numSamples, framerateReductionLimit, lengthLimit);
    long framerateReductionFactor = calcFramerateReductionFactor(1, processedAudio.numFrames, framerateReductionLimit, lengthLimit);
    processedAudio.framerate = round(audio->sampleRate / framerateReductionFactor);
    // This is an interleaved and potentially downsampled data buffer. Integer division will floor.
    processedAudio.data = malloc(processedAudio.numChannels * processedAudio.numFrames / framerateReductionFactor * sizeof(float));
    if (!processedAudio.data)
    {
        return -1;
    }

    prepareAudioForLoudnessCalc(audio, &processedAudio, framerateReductionFactor);

    int rc = calcIntegratedLoudness(&processedAudio, loudness);

    free(processedAudio.data);

    return rc;
}

long calcFrameLimit(long numFrames, long framerateReductionLimit, long lengthLimit)
{
    // Integer truncation is important here, so we can't just use min.
    if (numFrames/framerateReductionLimit > lengthLimit)
    {
        return lengthLimit * framerateReductionLimit;
    }
    return numFrames;
}

long calcFramerateReductionFactor(long framerateReductionFactor, long numFrames, long framerateReductionLimit, long lengthLimit)
{
    // Integer truncation is important here, so we can't just use min.
    if (numFrames/framerateReductionFactor > lengthLimit) {
        return min(framerateReductionLimit, ceilf((float)numFrames / lengthLimit));
    }
    return framerateReductionFactor;
}

void reduceFramerate(float *dataFloat, vDSP_Stride inputStride, vDSP_Length n, long framerateReductionFactor, float *reducedData, vDSP_Stride outputStride)
{
    // reducedData should have a length of at least
    // outputStride*floor(n/framerateReductionFactor) - (outputStride - 1)
    // in order to fit floor(n/framerateReductionFactor) averaged windows strided
    // by outputStride within reducedData
    
    // No reducing to be done if the factor is 1
    if (framerateReductionFactor == 1)
    {
        if (inputStride == 1 && outputStride == 1)
        {
            // Common case in which a simple memcpy suffices
            memcpy(reducedData, dataFloat, n*sizeof(float));
        }
        else
        {
            // Need to use vDSP to handle strided input/output
            float zero = 0;
            vDSP_vsadd(dataFloat, inputStride, &zero, reducedData, outputStride, n);
        }
        return;
    }

    vDSP_Length nWindows = max(0, (long)n - framerateReductionFactor + 1);
    if (nWindows == 0)  // Nothing to be done
        return;
    
    float *slidingSum = malloc(nWindows * sizeof(float));
    vDSP_vswsum(dataFloat, inputStride, slidingSum, 1, nWindows, framerateReductionFactor);
    
    float divisor = (float)framerateReductionFactor;
    vDSP_vsdiv(slidingSum, framerateReductionFactor, &divisor, reducedData, outputStride, n / framerateReductionFactor);   // Integer division will floor n/framerateReductionFactor
    
    free(slidingSum);
}
void audioFormatToFloatFormat(const AudioData *audio, AudioDataFloat *audioFloat, long framerateReductionFactor)
{
    vDSP_Stride stride = 1;
    int numChannels = audio->audioBuffer.mNumberChannels;
    
    // Convert audio data to float if not already.
    float *workArray = audio->audioBuffer.mData;
    
    // Convert to non-interleaved audio to populate channels.
    float* channel0 = malloc(audioFloat->numFrames * sizeof(float));
    float zero = 0;
    vDSP_vsadd(workArray, numChannels, &zero, channel0, stride, audioFloat->numFrames);
    reduceFramerate(channel0, stride, audioFloat->numFrames, framerateReductionFactor, audioFloat->channel0, stride);
    free(channel0);
    
    float* channel1 = malloc(audioFloat->numFrames * sizeof(float));
    vDSP_vsadd(workArray + 1, numChannels, &zero, channel1, stride, audioFloat->numFrames);
    reduceFramerate(channel1, stride, audioFloat->numFrames, framerateReductionFactor, audioFloat->channel1, stride);
    free(channel1);
    
    audioFloat->numFrames /= framerateReductionFactor;  // Integer division will floor.
}
void prepareAudioForLoudnessCalc(const AudioData *audio, AudioData_ebur128 *audioOut, long framerateReductionFactor)
{
    // Convert audio data to float if not already.
    float *src = audio->audioBuffer.mData;

    // The audio data is already interleaved, but we might want to reduce the framerate, so
    // we need to work with each channel separately via strided operations
    for (UInt32 i = 0; i < audio->audioBuffer.mNumberChannels; i++)
    {
        vDSP_Stride stride = audio->audioBuffer.mNumberChannels;
        // Reduce framerate while keeping the audio data interleaved
        reduceFramerate(src + i, stride, audioOut->numFrames, framerateReductionFactor, audioOut->data + i, stride);
    }
    audioOut->numFrames /= framerateReductionFactor;  // Integer division will floor.
}
void fillMonoSignalData(AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float half = 0.5;
    vDSP_vasm(audioFloat->channel0, stride, audioFloat->channel1, stride, &half, audioFloat->mono, stride, audioFloat->numFrames);
}
