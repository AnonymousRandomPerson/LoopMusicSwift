#import "LoopFinderAuto.h"
#import "LoopFinderAuto+differencing.h"
#import "LoopFinderAuto+spectra.h"
#import "LoopFinderAuto+analysis.h"
#import "LoopFinderAuto+synthesis.h"
#import "LoopFinderAuto+fadeDetection.h"

@implementation LoopFinderAuto

@synthesize nBestDurations, nBestPairs, leftIgnore, rightIgnore, sampleDiffTol, minLoopLength, minTimeDiff, fftLength, overlapPercent, t1Estimate, t2Estimate, tauRadius, t1Radius, t2Radius, tauPenalty, t1Penalty, t2Penalty, useFadeDetection, useMonoAudio, framerateReductionFactor, framerate, effectiveFramerate, lengthLimit, framerateReductionLimit, fftSetup, nSetup;

- (id)init
{
    t1Estimate = -1;
    t2Estimate = -1;
    [self useDefaultParams];
    
    return self;
}

- (void)useDefaultParams
{
    // INTERNAL VALUES
    firstFrame = 0;
//    nFrames = 0;    // Placeholder value
    
    avgVol = 0;     // Placeholder value
    dBLevel = 60;
    
    noiseRegularization = 1e-3;
    confidenceRegularization = 2.5;
    
    // PARAMETERS
    nBestDurations = 12;
    nBestPairs = 5;
    
    leftIgnore = 15;
    rightIgnore = 5;
    sampleDiffTol = 0.05;
    minLoopLength = 5;
    minTimeDiff = 0.5;
    fftLength = (1 << 15);
    overlapPercent = 50;
    
    tauRadius = 1;
    t1Radius = 1;
    t2Radius = 1;
    
    tauPenalty = 0;
    t1Penalty = 0;
    t2Penalty = 0;
    
    useFadeDetection = false;
    useMonoAudio = true;
    framerateReductionFactor = 6;
    
    lengthLimit = 1 << 21;   // Anything above around 3200000 will lead to crashes.
    framerateReductionLimit = 10; // Any lower and the typical human-audible frequencies will be unresolvable.
    
//    nSetup = 0;
}

// Helpers for input validation of numbers floored at a minimum value or kept within a range.
- (float)sanitizeFloat: (float)inputValue :(float)minValue
{
    return MAX(inputValue, minValue);
}
- (float)sanitizeFloat: (float)inputValue :(float)minValue :(float)maxValue
{
    return MIN(MAX(inputValue, minValue), maxValue);
}
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue
{
    return MAX(inputValue, minValue);
}
- (NSInteger)sanitizeInt: (NSInteger)inputValue :(NSInteger)minValue :(NSInteger)maxValue
{
    return MIN(MAX(inputValue, minValue), maxValue);
}


// Custom setters with validation
- (void)setNBestDurations:(NSInteger)nBestDurations
{
    self->nBestDurations = [self sanitizeInt:nBestDurations:1];
}
- (void)setNBestPairs:(NSInteger)nBestPairs
{
    self->nBestPairs = [self sanitizeInt:nBestPairs:1];
}
- (void)setLeftIgnore:(float)leftIgnore
{
    self->leftIgnore = [self sanitizeFloat:leftIgnore :0];
}
- (void)setRightIgnore:(float)rightIgnore
{
    self->rightIgnore = [self sanitizeFloat:rightIgnore :0];
}
- (void)setMinLoopLength:(float)minLoopLength
{
    self->minLoopLength = [self sanitizeFloat:minLoopLength :0];
}
- (void)setMinTimeDiff:(float)minTimeDiff
{
    self->minTimeDiff = [self sanitizeFloat:minTimeDiff :0];
}

- (void)setFftLength:(UInt32)fftLength
{
    // 0 doesn't work. 1 causes problems with vDSP because it's odd.
    if (fftLength < 2)
    {
        self->fftLength = 2;
        return;
    }
    
    // Rounds to the nearest power of 2, picking the higher one if tied.
    UInt32 next2 = [self nextPow2:fftLength];
    self->fftLength = (next2 - fftLength > fftLength - (next2 >> 1)) ? next2 >> 1 : next2;
}
// Helper for setFftLength to calculate the next highest power of 2
- (UInt32)nextPow2:(UInt32)num
{
    num--;
    num |= num >> 1;
    num |= num >> 2;
    num |= num >> 4;
    num |= num >> 8;
    num |= num >> 16;
    return MAX(2, ++num); // 0 doesn't work. 1 causes problems with vDSP because it's odd.
}
- (void)setOverlapPercent:(float)overlapPercent
{
    self->overlapPercent = [self sanitizeFloat:overlapPercent :0 :100];
}
- (void)setT1Radius:(float)t1Radius
{
    self->t1Radius = [self sanitizeFloat:t1Radius :0];
}
- (void)setT2Radius:(float)t2Radius
{
    self->t2Radius = [self sanitizeFloat:t2Radius :0];
}
- (void)setTauRadius:(float)tauRadius
{
    self->tauRadius = [self sanitizeFloat:tauRadius :0];
}
- (void)setT1Penalty:(float)t1Penalty
{
    self->t1Penalty = [self sanitizeFloat:t1Penalty :0 : 1];
}
- (void)setT2Penalty:(float)t2Penalty
{
    self->t2Penalty = [self sanitizeFloat:t2Penalty :0 : 1];
}
- (void)setTauPenalty:(float)tauPenalty
{
    self->tauPenalty = [self sanitizeFloat:tauPenalty :0 : 1];
}
- (void)setFramerateReductionFactor:(int)framerateReductionFactor
{
    self->framerateReductionFactor = [self sanitizeInt:framerateReductionFactor :1 :(int)self->framerateReductionLimit];
}
- (void)setFramerateReductionLimit:(float)framerateReductionLimit
{
    self->framerateReductionLimit = [self sanitizeInt:roundf(framerateReductionLimit) :1];
}
- (void)setFramerateReductionLimitFloat:(float)framerateReductionLimit
{
    self->framerateReductionLimit = framerateReductionLimit;
}

- (float)lengthLimit
{
    // Return value in minutes. Depends on the maximum framerate reduction limit.
    return (float)self->lengthLimit / self->framerate / 60 * self->framerateReductionLimit;
}
- (void)setLengthLimit:(float)lengthLimit
{
    // Set by the number of minutes. The set value depends on the framerate reduction limit.
    // Limit frame count between 2 and 2^22.
    self->lengthLimit = [self sanitizeInt:roundf(lengthLimit / self->framerateReductionLimit * 60 * self->framerate) :2 : (1 << 22)];
}
- (void)setLengthLimitFloat:(float)lengthLimit
{
    self->lengthLimit = lengthLimit;
}

- (bool)hasT1Estimate
{
    return self.t1Estimate != -1;
}
- (bool)hasT2Estimate
{
    return self.t2Estimate != -1;
}

- (loopModeValue)loopMode
{
    if ([self hasT1Estimate] && [self hasT2Estimate])
        return loopModeT1T2;
    else if ([self hasT1Estimate])
        return loopModeT1Only;
    else if ([self hasT2Estimate])
        return loopModeT2Only;
    else
        return loopModeAuto;
}

- (UInt32)s1Estimate
{
    return roundf(self.t1Estimate * self.effectiveFramerate);
}

- (UInt32)s2Estimate
{
    return roundf(self.t2Estimate * self.effectiveFramerate);
}


- (float)lastTime:(UInt32)numFrames
{
    return (float)(MAX(numFrames, 1) - 1) / self.effectiveFramerate;  // Floor at 0.
}
// Helper for the three limit functions below.
- (NSArray *)estimateLimits:(UInt32)numFrames :(float)estimate :(float)penalty :(float)radius
{
    float lastFrameTime = [self lastTime:numFrames];
    if (penalty == 1)
        return @[[NSNumber numberWithFloat:estimate], [NSNumber numberWithFloat:estimate]];
    else if(penalty == 0)
        return @[[NSNumber numberWithFloat:[self sanitizeFloat:estimate-radius :0 :lastFrameTime]], [NSNumber numberWithFloat:[self sanitizeFloat:estimate+radius :0 :lastFrameTime]]];
    else
    {
        float minVal = [self sanitizeFloat:MAX(estimate - 1.0/[self slopeFromPenalty:penalty] + 1.0/self.effectiveFramerate, estimate-radius) :0 :lastFrameTime];
        float maxVal = [self sanitizeFloat:MIN(estimate + 1.0/[self slopeFromPenalty:penalty] - 1.0/self.effectiveFramerate, estimate+radius) :0 :lastFrameTime];
        return @[[NSNumber numberWithFloat:minVal], [NSNumber numberWithFloat:maxVal]];
    }
}
- (NSArray *)tauLimits:(UInt32)numFrames
{
    if ([self loopMode] != loopModeT1T2)
        return @[[NSNumber numberWithFloat:self.minLoopLength], [NSNumber numberWithFloat:[self lastTime:numFrames]]];
    
    return [self estimateLimits:numFrames :self.t2Estimate - self.t1Estimate :self.tauPenalty :self.tauRadius];
}
- (NSArray *)t1Limits:(UInt32)numFrames
{
    if (![self hasT1Estimate])
    {
        if (![self hasT2Estimate])  // Ensures that when t2Limits calls t1Limits, infinite loops don't occur.
            return @[@0, [NSNumber numberWithFloat:[self lastTime:numFrames]-self.minLoopLength]];
        else
            return @[@0, [NSNumber numberWithFloat:[self sanitizeFloat:[[self t2Limits:numFrames][1] floatValue] - self.minLoopLength :0]]];
    }
    
    return [self estimateLimits:numFrames :self.t1Estimate :self.t1Penalty :self.t1Radius];
}
- (NSArray *)t2Limits:(UInt32)numFrames
{
    if (![self hasT2Estimate])
    {
        float lastFrameTime = [self lastTime:numFrames];
        if (![self hasT1Estimate])  // Ensures that when t1Limits calls t2Limits, infinite loops don't occur.
            return @[[NSNumber numberWithFloat:self.minLoopLength], [NSNumber numberWithFloat:lastFrameTime]];
        else
        {
            return @[[NSNumber numberWithFloat:[self sanitizeFloat:[[self t1Limits:numFrames][0] floatValue] + self.minLoopLength :0 :lastFrameTime]], [NSNumber numberWithFloat:lastFrameTime]];
        }
    }
    
    return [self estimateLimits:numFrames :self.t2Estimate :self.t2Penalty :self.t2Radius];
}


- (float)slopeFromPenalty:(float)penalty
{
    return tanf(penalty * M_PI/2);
}

- (void)performFFTSetup:(AudioDataFloat *)audio
{
    // For a sample of length n, an FFT of at least 2n-1 is needed for a cross-correlation between two vectors of length n. Round 2n-1 up to the nearest power of 2 for FFT.
    [self performFFTSetupOfSize:[self nextPow2:(2*audio->numFrames - 1)]];
}
// Skeleton for performFFTSetup and peformFFTSetup:
- (void)performFFTSetupOfSize:(unsigned long)n
{
//    NSLog(@"Existing n: %lu", nSetup);
    // Perform setup only if necessary.
    if (n > nSetup)
    {
        NSLog(@"Setting up FFT of length %lu", n);
        vDSP_destroy_fftsetup(fftSetup);
        fftSetup = vDSP_create_fftsetup(lround(log2(n)), kFFTRadix2);
        nSetup = n;
        NSLog(@"Done setting up FFT.");
    }
}
- (void)performFFTDestroy
{
    vDSP_destroy_fftsetup(self->fftSetup); // This does nothing if passed a null pointer.
    self->fftSetup = NULL;  // Nullify dangling pointer.
    self->nSetup = 0;
    NSLog(@"Done destroying FFT.");
}



- (NSDictionary *)findLoop:(const AudioData *)audio
{
    // To hold the floating-point-converted audio data.
    AudioDataFloat *floatAudio = malloc(sizeof(AudioDataFloat));
    framerate = audio->sampleRate;
    
    // Remove fade if specified.
    floatAudio->numFrames = audio->numSamples;
    if (self.useFadeDetection)
    {
        UInt32 fadeStart = [self detectFade:audio];
        if (fadeStart != 0)
            floatAudio->numFrames = fadeStart;
    }
    
    // Truncate the audio signal if absolutely necessary
    if (floatAudio->numFrames/framerateReductionLimit > lengthLimit)
    {
        floatAudio->numFrames = lengthLimit * framerateReductionLimit;
        NSLog(@"Audio track is too long. Truncating signal.");
    }
    // Reduce the framerate if necessary to improve performance. If the current reduction factor isn't enough, make it so it is.
    if (floatAudio->numFrames/self.framerateReductionFactor > lengthLimit)
    {
        self.framerateReductionFactor = MIN(framerateReductionLimit, ceilf((float)floatAudio->numFrames / lengthLimit));
        NSLog(@"Audio track is too long. Reducing framerate by a factor of %i for analysis.", self.framerateReductionFactor);
    }
    self.effectiveFramerate = (float)framerate / self.framerateReductionFactor;
    
    // Convert audio to 32-bit floating point audio, with the necessary framerate reduction (also modifies floatAudio->numFrames)
    floatAudio->channel0 = malloc(floatAudio->numFrames/self.framerateReductionFactor * sizeof(float));  // Integer division will floor.
    floatAudio->channel1 = malloc(floatAudio->numFrames/self.framerateReductionFactor * sizeof(float));
    audioFormatToFloatFormat(audio, floatAudio, self.framerateReductionFactor);
    
    if (self.useMonoAudio)
    {
        floatAudio->mono = malloc(floatAudio->numFrames * sizeof(float));
        fillMonoSignalData(floatAudio);
    }
    
    // Calculate average decibel level.
    avgVol = calcAvgVolume(floatAudio);
    
    // Prepare the FFT if needed
    [self performFFTSetup:floatAudio]; // THIS IS EXPENSIVE
    
    // Perform the algorithm
    NSDictionary *results;
    if ([self loopMode] == loopModeAuto)
    {
        results = [self findLoopNoEst:floatAudio];
        NSLog(@"RESULTS: %@", results);
    }
    else
    {
        results = [self findLoopWithEst:floatAudio];
        NSLog(@"RESULTS WITH ESTIMATES: %@", results);
    }
    
    
    if (self.useMonoAudio)
        free(floatAudio->mono);
    free(floatAudio->channel0);
    free(floatAudio->channel1);
    free(floatAudio);
    
    return [self restoreGlobalFramerate:results :self.framerateReductionFactor];
}


// Helper function
- (NSDictionary *)restoreGlobalFramerate:(NSDictionary *)results :(NSInteger)framerateReductionFactor
{
    if (framerateReductionFactor == 1)  // No changes to be done
        return results;
    
    
    // Converts the output of the loop finding algorithm under its own effective framerate to the actual global framerate.
    NSDictionary *modifiedArrays = @{@"baseDurations": [[NSMutableArray alloc] initWithCapacity:[results[@"baseDurations"] count]],
                                     @"startFrames": [[NSMutableArray alloc] initWithCapacity:[results[@"baseDurations"] count]],
                                     @"endFrames": [[NSMutableArray alloc] initWithCapacity:[results[@"baseDurations"] count]]
                                     };

    for (NSUInteger i = 0; i < [results[@"baseDurations"] count]; i++)
    {
        NSUInteger baseDuration = [results[@"baseDurations"][i] unsignedIntegerValue] * framerateReductionFactor;
        [modifiedArrays[@"baseDurations"] addObject:[NSNumber numberWithUnsignedInteger:baseDuration]];
        
        for (id key in @[@"startFrames", @"endFrames"])
        {
            NSMutableArray *innerArray = [[NSMutableArray alloc] initWithCapacity:[results[key][i] count]];
            for (NSUInteger j = 0; j < [results[key][i] count]; j++)
            {
                NSUInteger modifiedVal = [results[key][i][j] unsignedIntegerValue] * framerateReductionFactor;
                [innerArray addObject:[NSNumber numberWithUnsignedInteger:modifiedVal]];
            }
            [modifiedArrays[key] addObject:[innerArray copy]];
        }
    }

    return @{@"baseDurations": [modifiedArrays[@"baseDurations"] copy],
             @"startFrames": [modifiedArrays[@"startFrames"] copy],
             @"endFrames": [modifiedArrays[@"endFrames"] copy],
             @"sampleDifferences": results[@"sampleDifferences"],
             @"confidences": results[@"confidences"]
             };
}

@end
