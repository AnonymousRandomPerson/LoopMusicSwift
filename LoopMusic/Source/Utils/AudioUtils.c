#include "AudioUtils.h"

const float DB_REFERENCE_POWER = 1e-12;

// Internal helper
long max(long a, long b) {
    return a > b ? a : b;
}

float powToDB(float power)
{
    return 10 * log10(power / DB_REFERENCE_POWER);
}

float calcAvgPow(AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float channel0meansquare = 0;
    float channel1meansquare = 0;
    vDSP_measqv(audioFloat->channel0, stride, &channel0meansquare, audioFloat->numFrames);
    vDSP_measqv(audioFloat->channel1, stride, &channel1meansquare, audioFloat->numFrames);
    return (channel0meansquare + channel1meansquare) / 2;
}

float calcAvgVolume(AudioDataFloat *audioFloat)
{
    return powToDB(calcAvgPow(audioFloat));
}

void audio16bitToAudioFloat(SInt16 *data16bit, vDSP_Stride stride, float *dataFloat, vDSP_Length n)
{
    float maxAmp = 1 << 15;
    vDSP_vflt16(data16bit, stride, dataFloat, stride, n);
    vDSP_vsdiv(dataFloat, stride, &maxAmp, dataFloat, stride, n);
}

void audio32bitToAudioFloat(SInt32 *data32bit, vDSP_Stride stride, float *dataFloat, vDSP_Length n)
{
    float maxAmp = 1 << 31;
    vDSP_vflt32(data32bit, stride, dataFloat, stride, n);
    vDSP_vsdiv(dataFloat, stride, &maxAmp, dataFloat, stride, n);
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
    float *workArray;
    if (audio->audioType == FLOAT)
    {
        workArray = audio->audioBuffer.mData;
    }
    else
    {
        workArray = malloc(audioFloat->numFrames * numChannels * sizeof(float));
        if (audio->audioType == INT32)
        {
            audio32bitToAudioFloat((SInt32 *)audio->audioBuffer.mData, stride, workArray, audioFloat->numFrames * numChannels);
        }
        else
        {
            audio16bitToAudioFloat((SInt16 *)audio->audioBuffer.mData, stride, workArray, audioFloat->numFrames * numChannels);
        }
    }
    
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
    
    if (audio->audioType != FLOAT)
    {
        free(workArray);
    }
    
    audioFloat->numFrames /= framerateReductionFactor;  // Integer division will floor.
}
void fillMonoSignalData(AudioDataFloat *audioFloat)
{
    vDSP_Stride stride = 1;
    
    float half = 0.5;
    vDSP_vasm(audioFloat->channel0, stride, audioFloat->channel1, stride, &half, audioFloat->mono, stride, audioFloat->numFrames);
}
