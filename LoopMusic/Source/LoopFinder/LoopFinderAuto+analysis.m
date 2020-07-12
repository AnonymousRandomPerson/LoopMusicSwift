#import "LoopFinderAuto+analysis.h"
#import "LoopFinderAuto+differencing.h"

@implementation LoopFinderAuto (analysis)


// HELPER FUNCTIONS (for multiple) //
void fillRange(vDSP_Length *array, vDSP_Length start, vDSP_Length end)
{
    // Fills from start, up to but not including end.
    
    for (vDSP_Length i = start; i < end; i++)
        *(array + i-start) = i;
}

NSInteger findFirstToMeetCutoff(float *array, vDSP_Length n, float cutoff, bool aboveCutoff, bool reverseSearch)
{
    NSInteger start;
    NSInteger inc;
    
    if (reverseSearch)
    {
        start = n-1;
        inc = -1;
    }
    else
    {
        start = 0;
        inc = 1;
    }
    
    for (NSInteger i = 0; i < n; i++)
    {
        if ((!aboveCutoff && *(array + start + i*inc) <= cutoff) || (aboveCutoff && *(array + start + i*inc) >= cutoff))
            return start + i*inc;
    }
    
    return -1;
}


// HELPERS //
// For qsort, sorting indices by array value
typedef struct float_enumeration
{
    vDSP_Length index;
    float value;
} float_enumeration;

// For qsort
int compareValue(const void* a, const void* b)
{
    float float_a = ((float_enumeration *)a)->value;
    float float_b = ((float_enumeration *)b)->value;
    
    if (float_a == float_b)
        return 0;
    else if (float_a < float_b)
        return -1;
    else
        return 1;
}
// END HELPERS //

- (NSDictionary *)spacedMinima:(float *)array :(vDSP_Length)arraySize :(vDSP_Length)n
{
    if (n == 0)
        return @{@"indices": @[], @"values": @[]};
    
    // If n == 1, just use minimum function rather than sorting
    if (n == 1)
    {
        float minVal;
        vDSP_Length minI;
        vDSP_minvi(array, 1, &minVal, &minI, arraySize);
        
        return @{@"indices": @[[NSNumber numberWithUnsignedLong:minI]], @"values": @[[NSNumber numberWithFloat:minVal]]};
    }
    
    float_enumeration *sortedArray = malloc(arraySize * sizeof(float_enumeration));
    for (vDSP_Length i = 0; i < arraySize; i++)
    {
        (sortedArray + i)->index = i;
        (sortedArray + i)->value = *(array + i);
    }
    
    qsort(sortedArray, arraySize, sizeof(float_enumeration), compareValue); // TAKES QUITE A BIT OF TIME
    
    NSMutableArray *indices = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (vDSP_Length i = 0; i < arraySize; i++)
    {
        // Non-maximum suppression
        bool suppress = false;
        for (int j = 0; j < [indices count]; j++)
        {
            if (labs((NSInteger)((sortedArray + i)->index) - [indices[j] integerValue]) < self.minTimeDiff*self.effectiveFramerate)
            {
                suppress = true;
                break;
            }
        }
        
        if (!suppress)
        {
            [indices addObject:[NSNumber numberWithUnsignedInteger:(sortedArray + i)->index]];
            [values addObject:[NSNumber numberWithFloat:(sortedArray + i)->value]];
        }
        
        if ([indices count] >= n)
            break;
    }
    free(sortedArray);
    return @{@"indices": [indices copy], @"values": [values copy]};
}



// HELPER FUNCTIONS //
// For qsort
int cmp(const void* a, const void* b)
{
    float float_a = *((float *)a);
    float float_b = *((float *)b);
    
    if (float_a == float_b)
        return 0;
    else if (float_a < float_b)
        return -1;
    else
        return 1;
}

float medianSorted(float *array, vDSP_Length n)
{
    // array must be sorted.
    
    return n % 2 == 1 ? *(array + (n-1)/2) : (*(array + n/2 - 1) + *(array + n/2)) / 2;
}

float median(float *array, vDSP_Length n)
{
    float *sorted = malloc(n * sizeof(float));
    memcpy(sorted, array, n*sizeof(float));
    
    qsort(sorted, n, sizeof(float), cmp);
    
    float med = medianSorted(sorted, n);
    free(sorted);
    
    return med;
}

float sum(float *array, vDSP_Length n)
{
    float sumVal = 0;
    vDSP_sve(array, 1, &sumVal, n);
    return sumVal;
}

float nextAboveCutoff(float *array, vDSP_Length n, float cutoff)
{
    // array must be sorted in ascending order
    for (vDSP_Length i = 0; i < n; i++)
    {
        if (*(array + i) > cutoff)
            return *(array + i);
    }
    
    return -1;  // Control should never reach this point in its usage in inferLoopRegion().
}
// END HELPER FUNCTIONS //

- (NSDictionary *)inferLoopRegion:(float *)specMSEs :(vDSP_Length)nWindows :(float *)effectiveWindowDurations
{
    // If the desired loop length is too large to be attainable, just return the entire region.
    if (sum(effectiveWindowDurations, nWindows) < self.minLoopLength)
    {
        float maxVal;
        vDSP_maxv(specMSEs, 1, &maxVal, nWindows);
        
        return @{@"start": @0, @"end": [NSNumber numberWithUnsignedLong:nWindows-1], @"cutoff": [NSNumber numberWithFloat:maxVal]};
    }
    
    float windowStride = *effectiveWindowDurations;
    
    float *sortedSpecMSEs = malloc(nWindows * sizeof(float));
    memcpy(sortedSpecMSEs, specMSEs, nWindows * sizeof(float));
    qsort(sortedSpecMSEs, nWindows, sizeof(float), cmp);
    
    // Calculate initial cutoff based on the lowest few MSE values.
    float minMSE = *sortedSpecMSEs;
    vDSP_Length nFirstFew = lroundf(self.minLoopLength / windowStride);
    float rangeMultiplier = 2;
    float medianFirstFew = medianSorted(sortedSpecMSEs, nFirstFew);
    float cutoff = rangeMultiplier * (medianFirstFew - minMSE) + minMSE;
    
    NSInteger start = findFirstToMeetCutoff(specMSEs, nWindows, cutoff, false, false); // Find first below cutoff
    NSInteger end = findFirstToMeetCutoff(specMSEs, nWindows, cutoff, false, true);
    
    while (start == -1 || end == -1 || sum(effectiveWindowDurations+start, end-start+1) < self.minLoopLength)
    {
        
        if (nFirstFew < nWindows)
        {
            // Include higher and higher values in the median evaluation
            medianFirstFew = medianSorted(sortedSpecMSEs, ++nFirstFew);
            cutoff = rangeMultiplier * (medianFirstFew - minMSE) + minMSE;
        }
        else
        {
            // Continue in the case of failure by slowly raising the bar. This will never get trapped in an infinite loop because at some point, the entire interval will be captured, which is already guaranteed to at least meet the minLoopLength requirement.
            cutoff = nextAboveCutoff(sortedSpecMSEs, nWindows, cutoff);
        }
        
        start = findFirstToMeetCutoff(specMSEs, nWindows, cutoff, false, false);
        end = findFirstToMeetCutoff(specMSEs, nWindows, cutoff, false, true);
    }
    
    
    // Pick the best cutoff out of 3 to best reflect the interval. Usually this cutoff will be looser than that used to determine the interval start and endpoints.
    
    // #1: some percentage (mRange) of the way from the (median of the lowest few [nFirstFew]) to the (median of the highest few [nMax] after ignoring the actual highest ones [ignorePercent]).
    // For when the MSEs exhibit a large range of values, from small to large. The cutoff should be above the small values, but below the large values.
    float nMaxPercent = 0.05;
    vDSP_Length nMax = MAX(lroundf(self.minLoopLength / windowStride), lroundf(nMaxPercent * nWindows));
    
    float ignorePercent = 0.05;
    vDSP_Length nIgnore = lroundf(ignorePercent * nWindows);
    
    float mRange = 0.05;
    float cutoff1 = mRange * (medianSorted(sortedSpecMSEs + nWindows - nIgnore - nMax, nMax) - medianFirstFew) + medianFirstFew;
    free(sortedSpecMSEs);
    
    // #2: some multiple (based on the standard deviation of values in the interval) of some base value (the smaller of the mean/median of values in the interval). Use the minimum value as a reference rather than 0.
    // For when the MSEs are all very low values, and exhibit a relatively low variance. The cutoff should be higher than all of the low values.
    vDSP_Length intervalLength = end-start+1;
    float intervalMean, intervalSqMean;
    vDSP_meanv(specMSEs + start, 1, &intervalMean, intervalLength);
    vDSP_measqv(specMSEs + start, 1, &intervalSqMean, intervalLength);
    float intervalStd = sqrtf(intervalLength/MAX(1, intervalLength-1) * (intervalSqMean - pow(intervalMean, 2))); // sample standard deviation if possible
    float intervalMedian = median(specMSEs + start, end-start+1);
    float baseValue = MIN(intervalMean, intervalMedian) - minMSE;
    float baseMultiplier = MIN(5, MAX(1, 5/intervalStd));   // Cap at 5 and floor at 1.
    float cutoff2 = minMSE + baseMultiplier*baseValue;
    
    // #3: confidence regularization value
    // Having a cutoff below the regularization value would be overfitting.
    float cutoff3 = confidenceRegularization;
    
    cutoff = MAX(MAX(cutoff1, cutoff2), cutoff3);
    
    return @{@"start": [NSNumber numberWithInteger:start], @"end": [NSNumber numberWithInteger:end], @"cutoff": [NSNumber numberWithFloat:cutoff]};
}



- (float)calcMatchLength:(float *)specMSEs :(vDSP_Length)nWindows :(float *)effectiveWindowDurations :(float)cutoff
{
    float matchLength = 0;
    for (vDSP_Length i = 0; i < nWindows; i++)
    {
        if (*(specMSEs + i) <= cutoff)
        {
            matchLength += *(effectiveWindowDurations + i);
        }
    }
    
    return matchLength;
}

- (float)calcMismatchLength:(float *)specMSEs :(vDSP_Length)nWindows :(vDSP_Length)regionStart :(vDSP_Length)regionEnd :(float *)effectiveWindowDurations :(float)cutoff
{
    float mismatchLength = 0;
    
    vDSP_Length nOutOfLoop = regionStart + nWindows-regionEnd-1;
    vDSP_Length *outOfLoop = malloc(nOutOfLoop * sizeof(vDSP_Length));
    fillRange(outOfLoop, 0, regionStart);
    fillRange(outOfLoop+regionStart, regionEnd+1, nWindows);
    
    for (vDSP_Length i = 0; i < nOutOfLoop; i++)
    {
        vDSP_Length index = *(outOfLoop + i);
        if (*(specMSEs + index) > cutoff)
        {
            mismatchLength += *(effectiveWindowDurations + index);
        }
    }
    
    free(outOfLoop);
    
    return mismatchLength;
}



- (UInt32)refineLag:(AudioDataFloat *)audio :(UInt32)lag :(UInt32)regionStartSample :(UInt32)regionEndSample
{
    UInt32 startLagged = regionStartSample + lag;
    UInt32 endLagged =  regionEndSample + lag;
    
    float *mse = malloc((2*(regionEndSample - regionStartSample) + 1) * sizeof(float));
    [self audioMSE:audio :self.useMonoAudio :startLagged :endLagged :regionStartSample :regionEndSample :mse]; // TAKES TIME FOR LARGE REGIONS (SMALL LAGS)
    
    UInt32 zeroLagIndex = regionEndSample - regionStartSample;
    UInt32 radius = MIN(zeroLagIndex, (UInt32)lroundf(self.minTimeDiff/2.0 * self.effectiveFramerate));   // Search radius, in frames.
    
    float minMSE;  // Of no interest, just required for the vDSP_minvi call.
    vDSP_Length minIndex;
    vDSP_minvi(mse + zeroLagIndex-radius, 1, &minMSE, &minIndex, 2*radius+1);
    free(mse);
    
    NSInteger lagOffset = (NSInteger)minIndex - (NSInteger)radius;
    return (UInt32)((NSInteger)lag + lagOffset);
}




// HELPER FUNCTIONS //
void constrainStarts(vDSP_Length *starts, float *startsFloat, vDSP_Length nStarts, float lowerBound, float upperBound, NSInteger fillOffset, vDSP_Length *startsWorkArray, vDSP_Length *nNewStarts)
{
    // starts and startsFloat contain the same values, but of different types.
    // Returns starting values that are constrained to fit upper and lower limits in the array startsWorkArray (must be preallocated). nNewStarts has the number of entries that fit the constraints. fillOffset will be added to values of starts when filling startsWorkArray.
    
    NSInteger first = findFirstToMeetCutoff(startsFloat, nStarts, lowerBound, true, false);
    NSInteger last = findFirstToMeetCutoff(startsFloat, nStarts, upperBound, false, true);
    *nNewStarts = (first == -1 || last == -1 || last < first) ? 0 : last-first+1;
    
    for (NSInteger i = 0; i < *nNewStarts; i++)
        *(startsWorkArray + i) = *(starts+first + i) + fillOffset;
}

void calcSampleDiffs(AudioDataFloat *audio, UInt32 lag, vDSP_Length *starts, vDSP_Length nStarts, NSInteger windowRadius, float *sampleDiffs)
{
    vDSP_Stride stride = 1;
    
    float *diffs0 = malloc(nStarts * sizeof(float));
    vDSP_vsub(audio->channel0 + *starts, stride, audio->channel0 + lag + *starts, stride, diffs0, stride, nStarts);
    
    float *diffs1 = malloc(nStarts * sizeof(float));
    vDSP_vsub(audio->channel1 + *starts, stride, audio->channel1 + lag + *starts, stride, diffs1, stride, nStarts);

    vDSP_vmaxmg(diffs0, stride, diffs1, stride, diffs0, stride, nStarts);
    free(diffs1);
    
    if (windowRadius == 0)
    {
        memcpy(sampleDiffs, diffs0, nStarts);
    }
    else
    {
        // Middle
        vDSP_Length nMiddle = (vDSP_Length)MAX(0, (NSInteger)nStarts-2*windowRadius);
        vDSP_vswmax(diffs0, stride, sampleDiffs + windowRadius, stride, nMiddle, 2*windowRadius + 1);
        
        float maxMiddleDiff = 0;
        if (nMiddle > 0)
            vDSP_maxv(sampleDiffs + windowRadius, stride, &maxMiddleDiff, nMiddle);
        
        // Front and back
//        maxMiddleDiff = -1; // Don't penalize the edges.
        
        float currentFrontMax = 0;
        float currentBackMax = 0;
        for (vDSP_Length i = 0; i < MIN(windowRadius, nStarts); i++)
        {
            currentFrontMax = MAX(currentFrontMax, *(diffs0 + i));
            currentBackMax = MAX(currentBackMax, *(diffs0 + nStarts-1 - i));
        }
        for (vDSP_Length i = 0; i < MIN(windowRadius, nStarts); i++)
        {
            currentFrontMax = MAX(currentFrontMax, *(diffs0 + MIN(nStarts-1, MIN(windowRadius, nStarts) + i)));
            *(sampleDiffs + i) = currentFrontMax + maxMiddleDiff+1; // Always higher than the middle differences, but among themselves still retain order.
            
            currentBackMax = MAX(currentBackMax, *(diffs0 + MAX(0, nStarts-1 - MIN(windowRadius, nStarts) - i)));
            *(sampleDiffs + nStarts-1 - i) = currentBackMax + maxMiddleDiff+1;
        }
    }
    
    free(diffs0);
}

void applyDeviationPenalty(float *array, vDSP_Length *starts, vDSP_Length nStarts, float reference, float slope, float framerate)
{
    // Uses weights = 1 + slope * abs(startTimes - reference)
    for (vDSP_Length i = 0; i < nStarts; i++)
        *(array + i) *= 1 + slope * fabsf((float)(*(starts + i)) / framerate - reference);
}
- (NSDictionary *)getMinSampleDiffs :(float *)sampleDiffs :(vDSP_Length *)starts :(vDSP_Length)nStarts :(UInt32)lag
{
    // Returned dictionary has keys "starts", "sampleDiffs", and "lag".
    // If an initial estimate for the loop start or loop end is given, and a penalty value is 1, then the function assumes that <starts> is in ascending order and contains the start estimate, and/or that <starts>+lag contains the end estimate. Is these conditions are not satisfied, the correct estimates will be returned, but the corresponding sample differences may have invalid values (-1).
    
    // Handle no-variance-from-estimate cases
    if (([self hasT1Estimate] && self.t1Penalty == 1) || ([self hasT2Estimate] && self.t2Penalty == 1))
    {
        vDSP_Length s1Estimate = 0;
        if ([self hasT1Estimate] && self.t1Penalty == 1)
            s1Estimate = [self s1Estimate];
        else
            s1Estimate = MAX(0, (NSInteger)[self s2Estimate] - (NSInteger)lag);
        
        float sDiff = -1;
        if (s1Estimate >= *starts && s1Estimate <= *(starts + nStarts-1))
        {
            vDSP_Length index = s1Estimate - *starts;
            sDiff = *(sampleDiffs + index);
        }
        return @{@"starts": @[[NSNumber numberWithUnsignedInteger:s1Estimate]], @"sampleDiffs": @[[NSNumber numberWithFloat:sDiff]], @"lag": [NSNumber numberWithUnsignedInteger:lag]};
    }
    else    // Normal cases with variance
    {
        float *toMinimize = malloc(nStarts * sizeof(float));
        memcpy(toMinimize, sampleDiffs, nStarts * sizeof(float));
        
        // Do deviation penalties if necessary
        if ([self hasT1Estimate] && self.t1Penalty != 0)
            applyDeviationPenalty(toMinimize, starts, nStarts, self.t1Estimate, [self slopeFromPenalty:self.t1Penalty], self.effectiveFramerate);
        if ([self hasT2Estimate] && self.t2Penalty != 0)
            applyDeviationPenalty(toMinimize, starts, nStarts, self.t2Estimate - (float)lag/self.effectiveFramerate, [self slopeFromPenalty:self.t2Penalty], self.effectiveFramerate);
        
        NSArray *minIndexResults = [self spacedMinima:toMinimize :nStarts :self.nBestPairs][@"indices"];
        free(toMinimize);
        
        NSMutableArray *minStarts = [[NSMutableArray alloc] init];
        NSMutableArray *minDiffs = [[NSMutableArray alloc] init];
        for (vDSP_Length i = 0; i < [minIndexResults count]; i++)
        {
            vDSP_Length s1Estimate = *(starts + [minIndexResults[i] unsignedIntegerValue]);
            float sDiff = *(sampleDiffs + [minIndexResults[i] unsignedIntegerValue]);
            [minStarts addObject:[NSNumber numberWithUnsignedInteger:s1Estimate]];
            [minDiffs addObject:[NSNumber numberWithFloat:sDiff]];
        }
        
        return @{@"starts": [minStarts copy], @"sampleDiffs": [minDiffs copy], @"lag": [NSNumber numberWithUnsignedInteger:lag]};
    }
}

- (void)appendSingleResult:(NSDictionary *)store :(NSDictionary *)results :(NSUInteger)index
{
    // Check if repeat, and avoid adding if so.
    bool isRepeat = false;
    if ([store[@"starts"] containsObject:results[@"starts"][index]] &&
        [store[@"sampleDiffs"] containsObject:results[@"sampleDiffs"][index]] &&
        [store[@"lags"] containsObject:results[@"lag"]])
    {
        for (NSUInteger i = [store[@"starts"] indexOfObject:results[@"starts"][index]]; i < [store[@"starts"] count]; i++)
        {
            if ([store[@"starts"][i] unsignedIntegerValue] == [results[@"starts"][index] unsignedIntegerValue] &&
                [store[@"sampleDiffs"][i] floatValue] == [results[@"sampleDiffs"][index] floatValue] &&
                [store[@"lags"][i] integerValue] == [results[@"lag"] integerValue])
            {
                isRepeat = true;
                break;
            }
        }
    }
        
    
    if (!isRepeat)
    {
        [store[@"starts"] addObject:results[@"starts"][index]];
        [store[@"sampleDiffs"] addObject:results[@"sampleDiffs"][index]];
        [store[@"lags"] addObject:results[@"lag"]];
    }
}
- (void)appendEndpointResults:(NSDictionary *)store :(NSDictionary *)results
{
    // Appends results from a single output of getMinSampleDiffs onto a storage dictionary's array values, in ascending order of sample differences. Only appends results that meet self.sampleDiffTol. Stops if store's arrays reach self.nBestPairs long. Store should have keys "starts", "sampleDiffs", "lags", where each value is a mutable array.

    [self appendEndpointResults:store :results :@{@"starts": @[], @"sampleDiffs": @[], @"lag": @0}];    // Use dictionary with empty lists as second input dictionary.
}
- (void)appendEndpointResults:(NSDictionary *)store :(NSDictionary *)results1 :(NSDictionary *)results2
{
    // Same as the single output case, but with two outputs.
    
    NSUInteger i1 = 0;
    NSUInteger i2 = 0;
    NSUInteger results1Size = [results1[@"starts"] count];
    NSUInteger results2Size = [results2[@"starts"] count];
    
    // Do the merging
    bool cont1 = i1 < results1Size && [results1[@"sampleDiffs"][i1] floatValue] <= self.sampleDiffTol;;
    bool cont2 = i2 < results2Size && [results2[@"sampleDiffs"][i2] floatValue] <= self.sampleDiffTol;
    while (cont1 && cont2)
    {
        if ([store[@"starts"] count] >= self.nBestPairs)    // Maximum capacity
            return;
        
        // Possibly add results1 stuff
        if ([results1[@"sampleDiffs"][i1] floatValue] <= [results2[@"sampleDiffs"][i2] floatValue])
            [self appendSingleResult:store :results1 :i1++];

        if ([store[@"starts"] count] >= self.nBestPairs)    // Maximum capacity
            return;
        
        // Update cont1 before moving on.
        cont1 = i1 < results1Size && [results1[@"sampleDiffs"][i1] floatValue] <= self.sampleDiffTol;
        if (!cont1)
            break;
        
        // Possibly add results2 stuff
        if ([results1[@"sampleDiffs"][i1] floatValue] >= [results2[@"sampleDiffs"][i2] floatValue])
            [self appendSingleResult:store :results2 :i2++];
        
        cont2 = i2 < results2Size && [results2[@"sampleDiffs"][i2] floatValue] <= self.sampleDiffTol;
    }
    
    // Finish off
    if (!cont1 && !cont2)
        return;
    
    NSUInteger i, resultsSize;
    NSDictionary *results;
    
    if (cont1)
    {
        i = i1;
        resultsSize = results1Size;
        results = results1;
    }
    else
    {
        i = i2;
        resultsSize = results2Size;
        results = results2;
    }
    
    for (; i < resultsSize; i++)
    {
        if ([results[@"sampleDiffs"][i] floatValue] > self.sampleDiffTol)   // Tolerance condition
            return;
        
        if ([store[@"starts"] count] >= self.nBestPairs)    // Maximum capacity
            return;
        
        [self appendSingleResult:store :results :i];
    }
}
// END HELPER FUNCTIONS //

- (NSDictionary *)findEndpointPairsNoVariance:(AudioDataFloat *)audio :(UInt32)lag :(NSInteger)sDiffRadius
{
    vDSP_Length *startsWorkArray = malloc((2*sDiffRadius + 1) * sizeof(vDSP_Length));
    float *sampleDiffs = malloc((2*sDiffRadius + 1) * sizeof(float));

    lag = [self s2Estimate] - [self s1Estimate];
    vDSP_Length left = MAX(0, (NSInteger)[self s1Estimate] - sDiffRadius);   // Floor at 0.
    vDSP_Length right = MIN(audio->numFrames, (NSInteger)[self s1Estimate]+1 + sDiffRadius);    // 1 more than the right edge
    fillRange(startsWorkArray, left, right);
    calcSampleDiffs(audio, lag, startsWorkArray, right-left, sDiffRadius, sampleDiffs);
    float sDiff = *(sampleDiffs + [self s1Estimate]-left);

    free(startsWorkArray);
    free(sampleDiffs);

    return @{@"starts": @[[NSNumber numberWithUnsignedInteger:[self s1Estimate]]], @"lags": @[[NSNumber numberWithUnsignedInteger:lag]], @"sampleDiffs": @[[NSNumber numberWithFloat:sDiff]]};
}
- (NSDictionary *)findEndpointPairs:(AudioDataFloat *)audio :(UInt32)lag :(vDSP_Length *)starts :(vDSP_Length)nStarts
{
    NSInteger sDiffRadius = 1;  // Take the maximum sample difference of indices within ± radius.

    // No-variance case.
    if ([self loopMode] == loopModeT1T2 && self.t1Penalty == 1 && self.t2Penalty == 1)
        return [self findEndpointPairsNoVariance:audio :lag :sDiffRadius];

    // Typical case.
    vDSP_Length *startsWorkArray = malloc(nStarts * sizeof(vDSP_Length));
    vDSP_Length nNewStarts;
    
    // Convert to floats for comparisons
    float *startsFloat = malloc(nStarts * sizeof(float));
    for (NSUInteger i = 0; i < nStarts; i++)
        *(startsFloat + i) = (float)(*(starts + i));
    
    // Make sure neither the t1 constraints nor the t2 constraints are violated.
    NSArray *t1Lims = [self t1Limits:audio->numFrames];
    NSArray *t2Lims = [self t2Limits:audio->numFrames];
    constrainStarts(starts, startsFloat, nStarts, MAX([t1Lims[0] floatValue]*self.effectiveFramerate, [t2Lims[0] floatValue]*self.effectiveFramerate - lag), MIN([t1Lims[1] floatValue]*self.effectiveFramerate, [t2Lims[1] floatValue]*self.effectiveFramerate - lag), 0, startsWorkArray, &nNewStarts);

    float *sampleDiffs = malloc(nStarts * sizeof(float));

    NSDictionary *endpointPairs = @{@"starts": [[NSMutableArray alloc] init], @"sampleDiffs": [[NSMutableArray alloc] init], @"lags": [[NSMutableArray alloc] init]};
    
    calcSampleDiffs(audio, lag, startsWorkArray, nNewStarts, sDiffRadius, sampleDiffs);
    NSDictionary *initialResults = [self getMinSampleDiffs:sampleDiffs :startsWorkArray :nNewStarts :lag];

    [self appendEndpointResults:endpointPairs :initialResults];
    
    // If not enough pairs have been found, change things up a little.
    if ([endpointPairs[@"starts"] count] < self.nBestPairs)
    {
        
        NSArray *tauLims = [self tauLimits:audio->numFrames];   // To constrain the lag perturbations.
        
        bool incLagOnly = false;
        bool decLagOnly = false;
        NSInteger dlag = 1;
        while ([endpointPairs[@"starts"] count] < self.nBestPairs && labs(dlag) <= self.minTimeDiff*self.effectiveFramerate/2) // Only perturb lag by half a minTimeDiff window before giving up
        {
            UInt32 newLag = (UInt32)MAX(0, (NSInteger)lag + dlag);
            vDSP_Length nNewStarts;
            
            // Shift start samples. Make sure neither the t1 constraints nor the t2 constraints are violated.
            constrainStarts(starts, startsFloat, nStarts, MAX([t1Lims[0] floatValue]*self.effectiveFramerate + dlag, [t2Lims[0] floatValue]*self.effectiveFramerate - lag), MIN([t1Lims[1] floatValue]*self.effectiveFramerate + dlag, [t2Lims[1] floatValue]*self.effectiveFramerate - lag), -dlag, startsWorkArray, &nNewStarts);
            calcSampleDiffs(audio, newLag, startsWorkArray, nNewStarts, sDiffRadius, sampleDiffs);
            NSDictionary *results1 = [self getMinSampleDiffs:sampleDiffs :startsWorkArray :nNewStarts :newLag];
            
            
            // Shift end samples
            constrainStarts(starts, startsFloat, nStarts, MAX([t1Lims[0] floatValue]*self.effectiveFramerate, [t2Lims[0] floatValue]*self.effectiveFramerate - newLag), MIN([t1Lims[1] floatValue]*self.effectiveFramerate, [t2Lims[1] floatValue]*self.effectiveFramerate - newLag), 0, startsWorkArray, &nNewStarts);
            calcSampleDiffs(audio, newLag, startsWorkArray, nNewStarts, sDiffRadius, sampleDiffs);
            NSDictionary *results2 = [self getMinSampleDiffs:sampleDiffs :startsWorkArray :nNewStarts :newLag];
            
            
            // If both results are empty, just give up searching anymore.
            if ([results1[@"starts"] count] == 0 && [results2[@"starts"] count] == 0)
                break;
            
            [self appendEndpointResults:endpointPairs :results1 :results2];
            
            // Alter the lag perturbation in the necessary direction.
            if (incLagOnly)
                dlag++;
            else if (decLagOnly)
                dlag--;
            else if (dlag <= 0)
                dlag = 1 - dlag;
            else
                dlag = -dlag;
            
            if ((NSInteger)lag + dlag < [tauLims[0] floatValue] * self.effectiveFramerate)    // Lag is too small.
            {
                incLagOnly = true;
                dlag = labs(dlag) + 1;
            }
            
            if ((NSInteger)lag + dlag > [tauLims[1] floatValue] * self.effectiveFramerate)   // Lag is too large.
            {
                decLagOnly = true;
                dlag = -labs(dlag) - 1;
            }
            
            // If both flags are active, break because lag is out of range.
            if (incLagOnly && decLagOnly)
                break;
        }
    }

    free(startsWorkArray);
    free(startsFloat);
    free(sampleDiffs);
    
    // If the search failed, and still nothing was found, just use the best result from the initial batch.
    if ([endpointPairs[@"starts"] count] == 0)
    {
        if ([initialResults[@"starts"] count] > 0)
            return @{@"starts": @[initialResults[@"starts"][0]], @"sampleDiffs": @[initialResults[@"sampleDiffs"][0]], @"lags": @[initialResults[@"lag"]]};
        else
            // If there was literally nothing found, just default to starting from the beginning, and ending at the base lag value, and a negative sample difference as a flag for failure.
            // WOULD IT BE BETTER TO RETURN EMPTY?
            return @{@"starts": @[@0], @"sampleDiffs": @[@-1], @"lags": @[[NSNumber numberWithUnsignedInteger:lag]]};
    }
    
    // Make the guts immutable before returning.
    return @{@"starts": [endpointPairs[@"starts"] copy], @"sampleDiffs": [endpointPairs[@"sampleDiffs"] copy], @"lags": [endpointPairs[@"lags"] copy]};
}

- (NSDictionary *)findEndpointPairsSpectra: (AudioDataFloat *)audio :(UInt32)lag :(float *)specMSEs :(UInt32)nWindows :(UInt32 *)startSamples :(UInt32 *)windowSizes :(vDSP_Length)regionStart :(vDSP_Length)regionEnd
{
    float minVal;
    vDSP_Length minI;
    vDSP_minvi(specMSEs+regionStart, 1, &minVal, &minI, regionEnd-regionStart+1);

    vDSP_Length firstStart = *(startSamples + regionStart+minI);
    vDSP_Length lastStart = MIN(firstStart + *(windowSizes + regionStart+minI)-1, audio->numFrames - 1);    // Make sure it doesn't go out of bounds.

    vDSP_Length nStarts = lastStart - firstStart + 1;
    vDSP_Length *starts = malloc(nStarts * sizeof(vDSP_Length));
    fillRange(starts, firstStart, lastStart+1);

    NSDictionary *pairs = [self findEndpointPairs:audio :lag :starts :nStarts];
    free(starts);

    return pairs;
}




- (float)biasedMeanSpectrumMSE: (float *)specMSEs :(vDSP_Length)regionStart :(vDSP_Length)regionEnd
{
    return [self biasedMeanSpectrumMSE:specMSEs :regionStart :regionEnd :0.1];
}
- (float)biasedMeanSpectrumMSE: (float *)specMSEs :(vDSP_Length)regionStart :(vDSP_Length)regionEnd :(float)alpha
{
    alpha = MAX(0, MIN(alpha, 1));  // Enforce the [0, 1] proportion.
    
    vDSP_Length nInterval = regionEnd - regionStart + 1;
    float *intervalSpecMSEs = malloc(nInterval * sizeof(float));
    memcpy(intervalSpecMSEs, specMSEs+regionStart, nInterval * sizeof(float));
    qsort(intervalSpecMSEs, nInterval, sizeof(float), cmp);    // ascending order
    
    float meanMSE;
    vDSP_meanv(intervalSpecMSEs, 1, &meanMSE, MAX(1, nInterval - lroundf(alpha * nInterval)));  // Err on the side of exclusion, rather than inclusion, but make sure it's at least one.
    free(intervalSpecMSEs);
    
    return meanMSE;
}

@end
