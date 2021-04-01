#include "AudioUtils.h"

const float DB_REFERENCE_POWER = 1e-12;

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

float calcAvgVolumeFromBufferFormat(const AudioData *audio, long framerateReductionLimit, long lengthLimit)
{
    // Convert audio to 32-bit floating point audio, reducing framerate and truncating if necessary.
    AudioDataFloat *floatAudio = malloc(sizeof(AudioDataFloat));
    floatAudio->numFrames = calcFrameLimit(audio->numSamples, framerateReductionLimit, lengthLimit);
    floatAudio->channel0 = malloc(floatAudio->numFrames * sizeof(float));  // Integer division will floor.
    floatAudio->channel1 = malloc(floatAudio->numFrames * sizeof(float));
    audioFormatToFloatFormat(audio, floatAudio, calcFramerateReductionFactor(1, floatAudio->numFrames, framerateReductionLimit, lengthLimit));

    // Compute the average volume of the audio in floating-point format.
    float avgVol = calcAvgVolume(floatAudio);

    free(floatAudio->channel0);
    free(floatAudio->channel1);
    free(floatAudio);

    return avgVol;
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

void reduceFramerate(float *dataFloat, vDSP_Stride stride, vDSP_Length n, long framerateReductionFactor, float *reducedData)
{
    // reducedData should be floor(n/framerateReductionFactor) long.
    
    // No reducing to be done if the factor is 1
    if (framerateReductionFactor == 1)
    {
        memcpy(reducedData, dataFloat, n*sizeof(float));
        return;
    }
    
    vDSP_Length nWindows = max(0, (long)n - framerateReductionFactor + 1);
    if (nWindows == 0)  // Nothing to be done
        return;
    
    float *slidingSum = malloc(nWindows * sizeof(float));
    vDSP_vswsum(dataFloat, stride, slidingSum, stride, nWindows, framerateReductionFactor);
    
    float divisor = (float)framerateReductionFactor;
    vDSP_vsdiv(slidingSum, framerateReductionFactor*stride, &divisor, reducedData, stride, n / framerateReductionFactor);   // Integer division will floor n/framerateReductionFactor
    
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
    reduceFramerate(channel0, stride, audioFloat->numFrames, framerateReductionFactor, audioFloat->channel0);
    free(channel0);
    
    float* channel1 = malloc(audioFloat->numFrames * sizeof(float));
    vDSP_vsadd(workArray + 1, numChannels, &zero, channel1, stride, audioFloat->numFrames);
    reduceFramerate(channel1, stride, audioFloat->numFrames, framerateReductionFactor, audioFloat->channel1);
    free(channel1);
    
    audioFloat->numFrames /= framerateReductionFactor;  // Integer division will floor.
}
void fillMonoSignalData(AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float half = 0.5;
    vDSP_vasm(audioFloat->channel0, stride, audioFloat->channel1, stride, &half, audioFloat->mono, stride, audioFloat->numFrames);
}
