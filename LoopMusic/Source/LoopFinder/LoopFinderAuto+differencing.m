#import "LoopFinderAuto+differencing.h"

@implementation LoopFinderAuto (differencing)

// Does autoSlidingWeightedMSE on both channels and adds the MSEs.
- (void)audioAutoMSE:(AudioDataFloat *)audio :(float *)result
{
    [self audioAutoMSE:audio :false :result];
}
- (void)audioAutoMSE:(AudioDataFloat *)audio :(bool)useMono :(float *)result
{
    vDSP_Stride stride = 1;
    
    if (useMono)
    {
        [self autoSlidingWeightedMSE:audio->mono :audio->numFrames :result];
    }
    else
    {
        [self autoSlidingWeightedMSE:audio->channel0 :audio->numFrames :result];
        float *resultChannel1 = malloc(audio->numFrames * sizeof(float));
        [self autoSlidingWeightedMSE:audio->channel1 :audio->numFrames :resultChannel1];
        vDSP_vadd(result, stride, resultChannel1, stride, result, stride, audio->numFrames);
        
        free(resultChannel1);
    }
}

// Does slidingWeightedMSE between [startFirst, endFirst] and [startSecond, endSecond] on both channels and adds the MSEs.
- (void)audioMSE:(AudioDataFloat *)audio :(UInt32)startFirst :(UInt32)endFirst :(UInt32)startSecond :(UInt32)endSecond :(float *)result
{
    [self audioMSE:audio :false :startFirst :endFirst :startSecond :endSecond :result];
}
- (void)audioMSE:(AudioDataFloat *)audio :(bool)useMono :(UInt32)startFirst :(UInt32)endFirst :(UInt32)startSecond :(UInt32)endSecond :(float *)result
{
    vDSP_Stride stride = 1;
    vDSP_Length lengthFirst = endFirst - startFirst + 1;
    vDSP_Length lengthSecond = endSecond - startSecond + 1;
    vDSP_Length lengthResult = lengthFirst + lengthSecond - 1;
    
    if (useMono)
    {
        [self slidingWeightedMSE:audio->mono + startFirst :lengthFirst :audio->mono + startSecond :lengthSecond :result];
    }
    else
    {
        [self slidingWeightedMSE:audio->channel0 + startFirst :lengthFirst :audio->channel0 + startSecond :lengthSecond :result];
        float *resultChannel1 = malloc(lengthResult * sizeof(float));
        [self slidingWeightedMSE:audio->channel1 + startFirst :lengthFirst :audio->channel1 + startSecond :lengthSecond :resultChannel1];
        vDSP_vadd(result, stride, resultChannel1, stride, result, stride, lengthResult);
        
        free(resultChannel1);
    }
}


// Performs slidingWeightedMSE of a vector x with itself, and returns only the right half, due to symmetry. The size of result is n, the same size as x, representing MSE at all non-negative lag values, starting from zero.
- (void)autoSlidingWeightedMSE:(float *)x :(vDSP_Length)n :(float *)result
{
    float *fullSlidingMSE = malloc([self calcOutputLength:n :n] * sizeof(float));
    [self slidingWeightedMSE:x :n :x :n :fullSlidingMSE];
    memcpy(result, fullSlidingMSE + n-1, n * sizeof(float));
    free(fullSlidingMSE);
}
// Performs a noise-normalized (average power over the overlap interval) sliding MSE (SSE normalized by overlap interval length) calculation between signals a and b of lengths nA and nB, respectively. Result will be nA + nB - 1 elements long.
- (void)slidingWeightedMSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    
    [self slidingSSE:a :nA :b :nB :result];
    float *normFactors = malloc(outputLength * sizeof(float));
    
    [self calcNoiseAndOverlapLengthNormalizationFactors:a :nA :b :nB :normFactors];
    vDSP_vdiv(normFactors, stride, result, stride, result, stride, outputLength);
    free(normFactors);
}
// Performs a sliding sum-of-square-errors calculation, in the same manner as a cross-correlation, except summing the pointwise square differences between curves rather than the pointwise products.
- (void)slidingSSE:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    // SSE(tau) = -2*xcorr(tau) + sum(a(overlap window)^2) + sum(b(overlap window)^2)
    //          = -2*xcorr(tau) + combined_pwr_output(overlap window)
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    [self xcorr:a :nA :b :nB :result];
    
    float *combinedPowers = malloc(outputLength * sizeof(float));
    [self calcSlidingCombinedPowerOutput:a :nA :b :nB :combinedPowers];
    float negative2 = -2;
    vDSP_vsma(result, stride, &negative2, combinedPowers, stride, result, stride, outputLength);
    free(combinedPowers);
}
// Performs a cross-correlation between signals a and b of lengths nA and nB, respectively. Result will be nA + nB - 1 elements long. THIS FUNCTION IS THE PRIMARY BOTTLENECK.
- (void)xcorr:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)result
{
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length nMax = MAX(nA, nB);
    vDSP_Length nFFT = [self nextPow2:2*nMax-1];    // Also ensures nFFT >= 2
    vDSP_Length log2nFFT = log2(nFFT);
    
    float zero = 0;
    
    // zero-pad so that the cross-correlation ends up being the left-most part of the inverse fft, with only trailing zeros and no leading zeros.
    float *aPadded = malloc(nFFT * sizeof(float));
    vDSP_vfill(&zero, aPadded, stride, nB-1);
    vDSP_vfill(&zero, aPadded+outputLength, stride, nFFT-outputLength);
    memcpy(aPadded+nB-1, a, nA * sizeof(float));

    // Setup for FFT on aPadded.
    float *aSplitComplexMemory = malloc(nFFT * sizeof(float));
    DSPSplitComplex aSplitComplex = {aSplitComplexMemory, aSplitComplexMemory + nFFT/2};
    vDSP_ctoz((DSPComplex *)aPadded, 2*stride, &aSplitComplex, stride, nFFT/2);
    free(aPadded);
    
    // zero-pad b
    float *bPadded = malloc(nFFT * sizeof(float));
    vDSP_vfill(&zero, bPadded+nB, stride, nFFT-nB);
    memcpy(bPadded, b, nB * sizeof(float));
    
    // Setup for FFT on bPadded.
    float *bSplitComplexMemory = malloc(nFFT * sizeof(float));
    DSPSplitComplex bSplitComplex = {bSplitComplexMemory, bSplitComplexMemory + nFFT/2};
    vDSP_ctoz((DSPComplex *)bPadded, 2*stride, &bSplitComplex, stride, nFFT/2);
    free(bPadded);
    
    float *bufferMemory = malloc(2*nFFT * sizeof(float));   // 2x the size for later use in complex-complex inverse FFT
    DSPSplitComplex buffer = {bufferMemory, bufferMemory + nFFT/2};
    
    vDSP_fft_zript(self.fftSetup, &aSplitComplex, stride, &buffer, log2nFFT, kFFTDirection_Forward);
    vDSP_fft_zript(self.fftSetup, &bSplitComplex, stride, &buffer, log2nFFT, kFFTDirection_Forward);
    
    // Do unpacking of the FFT results and elementwise multiply aSplitComplex * conj(bSplitComplex), where aSplitComplex and bSplitComplex are the forward FFT results.
    float *fullXcorrMemory = malloc(2*nFFT * sizeof(float));
    DSPSplitComplex fullXcorr = {fullXcorrMemory, fullXcorrMemory + nFFT};
    
    vDSP_zvcmul(&bSplitComplex, stride, &aSplitComplex, stride, &fullXcorr, stride, nFFT/2);
    // Unpack and multiply the 0 and N/2 elements separately from the rest, due to packing format.
    *(fullXcorr.realp) = *(aSplitComplex.realp) * *(bSplitComplex.realp);
    *(fullXcorr.imagp) = 0;
    *(fullXcorr.realp + nFFT/2) = *(aSplitComplex.imagp) * *(bSplitComplex.imagp);
    *(fullXcorr.imagp + nFFT/2) = 0;
    
    free(aSplitComplexMemory);
    free(bSplitComplexMemory);
    
    // Normalize everything by 4 = 2^2, because each of the FFT values is scaled to be 2x the standard value.
    float normalizeFFT = 4;
    vDSP_vsdiv(fullXcorr.realp, stride, &normalizeFFT, fullXcorr.realp, stride, nFFT/2 + 1);
    vDSP_vsdiv(fullXcorr.imagp + 1, stride, &normalizeFFT, fullXcorr.imagp + 1, stride, nFFT/2 - 1);    // The 0 and n/2 + 1 elements are always 0, so no need to modify them.
    // Fill in the end of fullXcorr using the symmetry utilized in packing (mirrored around element nFFT/2, and disregarding element 0)
    vDSP_vsadd(fullXcorr.realp + 1, stride, &zero, fullXcorr.realp + nFFT-1, -stride, nFFT/2 - 1);
    float negative1 = -1;   // For flipping the sign on the imaginary part.
    vDSP_vsmul(fullXcorr.imagp + 1, stride, &negative1, fullXcorr.imagp + nFFT-1, -stride, nFFT/2 - 1);
    
    // Inverse FFT fullXcorr to get the actual cross-correlation, with zeros at the end.
    buffer.realp = bufferMemory; buffer.imagp = bufferMemory + nFFT;  // Resize the buffer.
    vDSP_fft_zipt(self.fftSetup, &fullXcorr, stride, &buffer, log2nFFT, kFFTDirection_Inverse);  // Note: complex FFT, not real FFT.
    free(bufferMemory);
    
    // Copy the first outputLength elements into <results> and ignore the trailing zeros. Normalize by nFFT, since complex inverse transforms use a scaling factor of that size.
    float scaleDown = (float)nFFT;
    vDSP_vsdiv(fullXcorr.realp, stride, &scaleDown, result, stride, outputLength);
    free(fullXcorrMemory);
}

// Supporting functions for slidingWeightedMSE to calculate the weights. The last argument is the output in each function.
- (void)calcNoiseAndOverlapLengthNormalizationFactors:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)normalizationFactors
{
    // Normalization for cross-correlation is done by regularized average power and sliding window overlap length.
    // The total combined power output is divided by 2*overlapLength to get the average power over the overlap window (/n) over both signals (/2). This value is then regularized by some predetermined small value to prevent division by zero.
    // The overlap length is used as-is.
    // Simple algebra results in a normalization factor of:
    //
    // combinedPower/2 + overlapLength*regularization
    //
    
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    float powerFactor = .5;
    float *combinedPowers = malloc(outputLength * sizeof(float));
    float *overlapLengths = malloc(outputLength * sizeof(float));
    
    [self calcSlidingCombinedPowerOutput:a :nA :b :nB :combinedPowers];
    [self calcSlidingOverlapLength:a :nA :b :nB :overlapLengths];
    
    vDSP_vsmsma(combinedPowers, stride, &powerFactor, overlapLengths, stride, &noiseRegularization, normalizationFactors, stride, outputLength);
    
    free(combinedPowers);
    free(overlapLengths);
}
- (void)calcSlidingCombinedPowerOutput:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)combinedPowerOutput
{
    // Sums the powers over the sliding cross-correlation overlap window across both signals.
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length minLength = MIN(nA, nB);
    float weight = 1;
    
    // Pad each side with a 0 because of how vDSP_vrsum works (it ignores the first element when it takes a running sum).
    float *aPowers = malloc((nA+2) * sizeof(float));
    float *bPowers = malloc((nB+2) * sizeof(float));
    *(aPowers) = 0;
    *(bPowers) = 0;
    *(aPowers + nA+1) = 0;
    *(bPowers + nB+1) = 0;
    vDSP_vsq(a, stride, aPowers+1, stride, nA);
    vDSP_vsq(b, stride, bPowers+1, stride, nB);
    
    // Left part of combinedPowerOutput
    // +1 length for the guaranteed zero in front due to vDSP_vrsum
    float *aPowerForwardRunSum = malloc((minLength+1) * sizeof(float));
    float *bPowerBackwardRunSum = malloc((minLength+1) * sizeof(float));
    vDSP_vrsum(aPowers, stride, &weight, aPowerForwardRunSum, stride, minLength+1);
    vDSP_vrsum(bPowers+nB+1, -stride, &weight, bPowerBackwardRunSum, stride, minLength+1);
    
    vDSP_vadd(aPowerForwardRunSum+1, stride, bPowerBackwardRunSum+1, stride, combinedPowerOutput, stride, minLength);
    
    // Middle part of combinedPowerOutput
    float smallPower = 0;
    vDSP_Length nSliding = outputLength - (2*minLength-1);
    float *slidingLargePower = malloc(nSliding * sizeof(float));
    if (nB < nA)
    {
        smallPower = *(bPowerBackwardRunSum+minLength); // Last element
        vDSP_vswsum(aPowers+2, stride, slidingLargePower, stride, nSliding, minLength); // Start at the 2nd possibly non-zero element a aPowers and assign to slidingLargePower forwards.
    }
    else
    {
        smallPower = *(aPowerForwardRunSum+minLength);  // Last element
        vDSP_vswsum(bPowers+1, stride, slidingLargePower+nSliding-1, -stride, nSliding, minLength); // Start at the 1st possibly non-zero element and assign to slidingLargePower backwards.
    }
    
    vDSP_vsadd(slidingLargePower, stride, &smallPower, combinedPowerOutput+minLength, stride, nSliding);
    
    free(aPowerForwardRunSum);
    free(bPowerBackwardRunSum);
    free(slidingLargePower);
    
    // Right part of combinedPowerOutput (for minLength - 1, not minLength)
    // +1 length for the guaranteed zero in front.
    float *aPowerBackwardRunSum = malloc(minLength * sizeof(float));
    float *bPowerForwardRunSum = malloc(minLength * sizeof(float));
    vDSP_vrsum(aPowers+nA+1, -stride, &weight, aPowerBackwardRunSum, stride, minLength);
    vDSP_vrsum(bPowers, stride, &weight, bPowerForwardRunSum, stride, minLength);
    
    vDSP_vadd(aPowerBackwardRunSum+1, stride, bPowerForwardRunSum+1, stride, combinedPowerOutput+outputLength-1, -stride, minLength-1);
    
    free(aPowerBackwardRunSum);
    free(bPowerForwardRunSum);
    
    
    free(aPowers);
    free(bPowers);
}
- (void)calcSlidingOverlapLength:(float *)a :(vDSP_Length)nA :(float *)b :(vDSP_Length)nB :(float *)overlapLengths
{
    // Sliding cross-correlation overlap window lengths.
    // Overlap lengths will be a trapezoidal shape, with a ramp up to a cap, then eventual ramp down.
    const vDSP_Stride stride = 1;
    vDSP_Length outputLength = [self calcOutputLength:nA :nB];
    vDSP_Length minLength = MIN(nA, nB);
    float minOverlap = 1;
    float overlapIncrement = 1;
    float maxOverlap = (float)minLength;
    
    vDSP_vramp(&minOverlap, &overlapIncrement, overlapLengths, stride, minLength);
    vDSP_vfill(&maxOverlap, overlapLengths + minLength, stride, outputLength - (2*minLength-1));
    vDSP_vramp(&minOverlap, &overlapIncrement, overlapLengths+outputLength-1, -stride, minLength-1);
}
// Calculates the length of the output vector for sliding differences, given the lengths of the input vectors.
- (vDSP_Length)calcOutputLength:(vDSP_Length)nA :(vDSP_Length)nB
{
    return nA + nB - 1;
}

@end
