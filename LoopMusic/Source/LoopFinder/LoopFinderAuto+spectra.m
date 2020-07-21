#import "LoopFinderAuto+spectra.h"


void freeDiffSpectrogramInfo(DiffSpectrogramInfo *info)
{
    free(info->mses);
    free(info->startSamples);
    free(info->windowSizes);
    free(info->effectiveWindowDurations);
}

@implementation LoopFinderAuto (spectra)

// Default smoothing radius is 2.
- (void)smoothen:(float *)signal :(vDSP_Length)n
{
    [self smoothen:signal :n :2];
}
// Does in-place rectangular smoothing to a signal of length n. Uses a specified radius over which to average. The radius must be less than the signal length.
- (void)smoothen:(float *)signal :(vDSP_Length)n :(vDSP_Length)radius
{
    vDSP_Stride stride = 1;
    
    // Handle the case where the averaging window covers the whole vector for every element.
    if (radius >= n-1)
    {
        float avgVal = 0;
        vDSP_meanv(signal, stride, &avgVal, n);
        vDSP_vfill(&avgVal, signal, stride, n);
        return;
    }
    
    
    
    // Work array
    float *smoothedSignal = malloc(n * sizeof(float));
    float one = 1;
    
    // Front
    vDSP_Length frontSize = MIN(radius+1, n-radius);
    
    // {
    vDSP_vrsum(signal + radius, stride, &one, smoothedSignal, stride, frontSize);
    float firstRplus1 = 0;
    vDSP_sve(signal, stride, &firstRplus1, radius + 1);
    vDSP_vsadd(smoothedSignal, stride, &firstRplus1, smoothedSignal, stride, frontSize);
    // } This whole thing is a cumulative sum, with the first value being the sum of the radius+1 first elements.
    
    // Normalize front
    float *lengths = malloc(frontSize * sizeof(float));
    float radiusPlusOne = radius + 1;
    vDSP_vramp(&radiusPlusOne, &one, lengths, stride, frontSize);
    vDSP_vdiv(lengths, stride, smoothedSignal, stride, smoothedSignal, stride, frontSize);
    
    
    // Back
    vDSP_Length backSize = frontSize - 1;
    vDSP_vrsum(signal + n-1 - radius, -stride, &one, smoothedSignal + n-1, -stride, backSize);
    float lastRplus1 = 0;
    vDSP_sve(signal + n-1, -stride, &lastRplus1, radius + 1);
    vDSP_vsadd(smoothedSignal + n-1, -stride, &lastRplus1, smoothedSignal + n-1, -stride, backSize);
    
    // Normalize back
    vDSP_vdiv(lengths, stride, smoothedSignal + n-1, -stride, smoothedSignal + n-1, -stride, backSize);
    
    free(lengths);
    
    
    // Handle the case where the window size is the vector length or greater.
    if (2*radius+1 >= n)
    {
        // Middle, mean of entire vector, repeated
        vDSP_vfill(smoothedSignal + n-radius-1, smoothedSignal + n-radius, stride, 2*radius - (n-1));
    }
    else    // Typical case, where radius is small compared to vector size.
    {
        // Middle, sliding sum
        vDSP_vswsum(signal+1, stride, smoothedSignal + radius+1, stride, n - (2*radius+1), 2*radius+1);
        float windowLength = (float)(2*radius+1);
        vDSP_vsdiv(smoothedSignal + radius+1, stride, &windowLength, smoothedSignal + radius+1, stride, n - (2*radius+1));
    }
    
    
    memcpy(signal, smoothedSignal, n * sizeof(float));
    free(smoothedSignal);
}


- (void)calcSpectrum:(float *)signal :(vDSP_Length)n :(float **)spectrum :(vDSP_Length *)nBins
{
    [self calcSpectrum:signal :n :spectrum :nBins :10000];
}
- (void)calcSpectrum:(float *)signal :(vDSP_Length)n :(float **)spectrum :(vDSP_Length *)nBins :(float)fmax
{
    vDSP_Stride stride = 1;
    float *paddedSignal = signal;
    vDSP_Length paddedN = [self nextPow2:n];
    
    if (n < paddedN)
    {
//        NSLog(@"Zero-padding...");
        
        float zero = 0;
        paddedSignal = malloc(paddedN * sizeof(float));
        memcpy(paddedSignal, signal, n * sizeof(float));
        vDSP_vfill(&zero, paddedSignal + n, stride, paddedN - n);
    }
    
    *nBins = MIN(1 + floorf(paddedN*fmax/self.effectiveFramerate), 1 + paddedN/2);
    *spectrum = malloc(*nBins * sizeof(float));
    
    
    float *signalSplitComplexMemory = malloc(paddedN * sizeof(float));
    float *bufferMemory = malloc(paddedN * sizeof(float));
    DSPSplitComplex signalSplitComplex = {signalSplitComplexMemory, signalSplitComplexMemory + paddedN/2};
    DSPSplitComplex buffer = {bufferMemory, bufferMemory + paddedN/2};
    
    vDSP_ctoz((DSPComplex *)paddedSignal, 2*stride, &signalSplitComplex, stride, paddedN/2);
    vDSP_fft_zript(self.fftSetup, &signalSplitComplex, stride, &buffer, log2(paddedN), kFFTDirection_Forward);
    free(bufferMemory);

    vDSP_zvabs(&signalSplitComplex, stride, *spectrum, stride, MIN(*nBins, paddedN/2));
    
    // Unpack the first and last bins separately
    **spectrum = fabs(*signalSplitComplex.realp / 2);
    if (2*fmax >= self.effectiveFramerate)    // Last bin will only be used if fmax reaches the Nyquist frequency
    {
        *(*spectrum + *nBins-1) = fabs(*signalSplitComplex.imagp / 2);
    }
    
    free(signalSplitComplexMemory);
    
    // Normalize by signal length
    float normalize = (float)paddedN;
    vDSP_vsdiv(*spectrum, stride, &normalize, *spectrum, stride, *nBins);
    
    // If a new padded array had to be allocated at the beginning of the function
    if (n < paddedN)
    {
//        NSLog(@"Releasing...");
        
        free(paddedSignal);
    }
    
    [self smoothen:*spectrum :*nBins :roundf(*nBins / 1024)];
}


- (void)spectrumMSE:(float *)a :(float *)b :(vDSP_Length)n :(float *)mse
{
    vDSP_Stride stride = 1;
    
    float *sqErrs = malloc(n * sizeof(float));
    float *aDB = malloc(n * sizeof(float));
    float *bDB = malloc(n * sizeof(float));
    
    vDSP_vdbcon(a, stride, &DB_REFERENCE_POWER, aDB, stride, n, 0);    // 0 flag for power.
    vDSP_vdbcon(b, stride, &DB_REFERENCE_POWER, bDB, stride, n, 0);
    // Raises the average decibel level to be whatever was specified as the dBLevel.
    float dbOffset = self->dBLevel - self->avgVol;
    vDSP_vsadd(aDB, stride, &dbOffset, aDB, stride, n);
    vDSP_vsadd(bDB, stride, &dbOffset, bDB, stride, n);
    vDSP_vsub(aDB, stride, bDB, stride, sqErrs, stride, n);
    vDSP_vsq(sqErrs, stride, sqErrs, stride, n);
    
    // This part makes the square difference zero if both signals are at or below the decibel level floor. Then it gets the MSE, normalized by the number of entries that weren't set to zero.
    float *loudEnough = malloc(n * sizeof(float));
    float *zeros = malloc(n * sizeof(float));
    float *ones = malloc(n * sizeof(float));
    float zero = 0;
    float one = 1;
    vDSP_vfill(&zero, zeros, stride, n);
    vDSP_vfill(&one, ones, stride, n);
    
    vDSP_vmax(aDB, stride, bDB, stride, loudEnough, stride, n);
    free(aDB);
    free(bDB);
    
    vDSP_vmax(loudEnough, stride, zeros, stride, loudEnough, stride, n);
    free(zeros);
    
    int nInt = (int)n;  // Needs to be an int for the vvceilf call.
    vvceilf(loudEnough, loudEnough, &nInt);
    vDSP_vmin(loudEnough, stride, ones, stride, loudEnough, stride, n); // After this, loudEnough is a vector of indicators for whether either signal is loud enough.
    free(ones);
    
    float nLoudEnough = 0;
    vDSP_sve(loudEnough, stride, &nLoudEnough, n);
    
    float maxSqErr = 0;
    vDSP_maxv(sqErrs, stride, &maxSqErr, n);
    maxSqErr += 1;
    vDSP_vsmul(loudEnough, stride, &maxSqErr, loudEnough, stride, n); // After this, loudEnough contains 0 for at or below the noise floor, and a number higher than any of the square errors if above the noise floor.
    
    vDSP_vmin(sqErrs, stride, loudEnough, stride, sqErrs, stride, n);
    free(loudEnough);
    
    vDSP_sve(sqErrs, stride, mse, n);
    free(sqErrs);
    
    *mse /= nLoudEnough;
}


- (void)diffSpectrogram:(AudioDataFloat *)signal :(UInt32)lag :(DiffSpectrogramInfo *)results
{
    UInt32 windowStride = MAX(1, roundf((1-self.overlapPercent/100)*self.fftLength));
    
    results->nWindows = ceilf((float)(signal->numFrames - lag) / windowStride);
    results->mses = malloc(results->nWindows * sizeof(float));
    results->startSamples = malloc(results->nWindows * sizeof(UInt32));
    results->windowSizes = malloc(results->nWindows * sizeof(UInt32));
    results->effectiveWindowDurations = malloc(results->nWindows * sizeof(float));
    
    float *spectrumPrimary = 0;
    float *spectrumLagged = 0;
    vDSP_Length nBins = 0;
    float mseChannel1 = 0;
    
    for (int i = 0; i < results->nWindows; i++)
    {
        *(results->startSamples + i) = i*windowStride;
        *(results->windowSizes + i) = MIN(self.fftLength, signal->numFrames - lag - i*windowStride);
        *(results->effectiveWindowDurations + i) = windowStride / self.effectiveFramerate;
        
        // Channel 0 or mono
        float *signalPtr = 0;
        if (self.useMonoAudio)
            signalPtr = signal->mono;
        else
            signalPtr = signal->channel0;
        
        [self calcSpectrum:signalPtr + i*windowStride :*(results->windowSizes + i) :&spectrumPrimary :&nBins];
        [self calcSpectrum:signalPtr + lag + i*windowStride :*(results->windowSizes + i) :&spectrumLagged :&nBins];
        [self spectrumMSE:spectrumPrimary :spectrumLagged :nBins :results->mses + i];
        // Free the memory allocated by calcSpectrum
        free(spectrumPrimary);
        free(spectrumLagged);
        signalPtr = 0;
        
        if (!self.useMonoAudio)
        {
            // Channel 1
            [self calcSpectrum:signal->channel1 + i*windowStride :*(results->windowSizes + i) :&spectrumPrimary :&nBins];
            [self calcSpectrum:signal->channel1 + lag + i*windowStride :*(results->windowSizes + i) :&spectrumLagged :&nBins];
            [self spectrumMSE:spectrumPrimary :spectrumLagged :nBins :&mseChannel1];
            free(spectrumPrimary);
            free(spectrumLagged);
        
            *(results->mses + i) += mseChannel1;
        }
    }
    *(results->effectiveWindowDurations + results->nWindows-1) = (signal->numFrames-lag - *(results->startSamples + results->nWindows-1)) / self.effectiveFramerate;
}

@end
