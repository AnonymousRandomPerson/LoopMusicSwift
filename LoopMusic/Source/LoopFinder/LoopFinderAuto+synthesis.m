#import "LoopFinderAuto+synthesis.h"
#import "LoopFinderAuto+differencing.h"
#import "LoopFinderAuto+spectra.h"
#import "LoopFinderAuto+analysis.h"

@implementation LoopFinderAuto (synthesis)

- (NSArray *)calcConfidence:(NSArray *)losses :(float)regularization
{
    // Handle 1-element cases (to avoid nan if the number is too big)
    if ([losses count] == 1)
        return @[@1];
    
    bool zeroDenom = false; // Flag for zero-division
    float sumInvs = 0;  // Sum of inverses
    
    NSMutableArray *workArray = [NSMutableArray arrayWithArray:losses];
    for (NSUInteger i = 0; i < [workArray count]; i++)
    {
        float denom = expf([workArray[i] floatValue])-1 + expf(regularization)-1;
        if (denom == 0)
        {
            zeroDenom = true;
            break;
        }
        
        float inv = 1.0/denom;
        sumInvs += inv;
        workArray[i] = [NSNumber numberWithFloat:inv];
    }
    
    // Handle the zero-division case.
    if (zeroDenom)
    {
        for (NSUInteger i = 0; i < [workArray count]; i++)
        {
            float denom = expf([losses[i] floatValue])-1 + expf(regularization)-1;
            
            float value = denom == 0 ? 1 : 0;
            workArray[i] = [NSNumber numberWithFloat:value];
        }
    }
    else    // The normal case
    {
        for (NSUInteger i = 0; i < [workArray count]; i++)
        {
            workArray[i] = [NSNumber numberWithFloat:[workArray[i] floatValue]/sumInvs];
        }
    }
    
    return [workArray copy];
}

- (NSArray *)calcConfidence:(NSArray *)losses
{
    return [self calcConfidence:losses :self->confidenceRegularization];
}


- (NSDictionary *)analyzeLagValue:(AudioDataFloat *)audio :(UInt32)lag
{
    DiffSpectrogramInfo *specDiff = malloc(sizeof(DiffSpectrogramInfo));
    [self diffSpectrogram:audio :lag :specDiff];    // TAKES A FAIR AMOUNT OF TIME FOR SMALL LAGS
    
    NSDictionary *loopRegion = [self inferLoopRegion:specDiff->mses :specDiff->nWindows :specDiff->effectiveWindowDurations];
    
    UInt32 regionStartWindow = (UInt32)[loopRegion[@"start"] unsignedIntegerValue];
    UInt32 regionEndWindow = (UInt32)[loopRegion[@"end"] unsignedIntegerValue];
    float regionCutoff = [loopRegion[@"cutoff"] floatValue];
    float matchLength = [self calcMatchLength:specDiff->mses :specDiff->nWindows :specDiff->effectiveWindowDurations :regionCutoff];
    float mismatchLength = [self calcMismatchLength:specDiff->mses :specDiff->nWindows :regionStartWindow :regionEndWindow :specDiff->effectiveWindowDurations :regionCutoff];
    
    UInt32 regionStartSample = *(specDiff->startSamples + regionStartWindow);
    UInt32 regionEndSample = *(specDiff->startSamples + regionEndWindow) + *(specDiff->windowSizes + regionEndWindow) - 1;
    lag = [self refineLag:audio :lag :regionStartSample :regionEndSample]; // TAKES QUITE A BIT OF TIME FOR SMALL LAGS
    
    NSDictionary *pairs = [self findEndpointPairsSpectra:audio :lag :specDiff->mses :specDiff->nWindows :specDiff->startSamples :specDiff->windowSizes :regionStartWindow :regionEndWindow];
    
    float specMSE = [self biasedMeanSpectrumMSE:specDiff->mses :regionStartWindow :regionEndWindow];
    
    freeDiffSpectrogramInfo(specDiff);
    free(specDiff);
    
    return @{@"startSamples": pairs[@"starts"],
             @"refinedLags": pairs[@"lags"],
             @"sampleDiffs": pairs[@"sampleDiffs"],
             @"spectrumMSE": [NSNumber numberWithFloat:specMSE],
             @"matchLength": [NSNumber numberWithFloat:matchLength],
             @"mismatchLength": [NSNumber numberWithFloat:mismatchLength]
             };
}


// HELPER HELPER FUNCTIONS //
// Generates an array from 0 to n-1
- (NSArray *)range:(NSUInteger)n
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:n];
    for (NSUInteger i = 0; i < n; i++)
        [array addObject:[NSNumber numberWithUnsignedInteger:i]];
    
    return [array copy];
}
/*!
 * Permutes the order of some elements within a mutable array.
 * @param array The array to be modified.
 * @param initial The initial indices to be replaced.
 * @param final The indices to replace initial.
 */
- (void)permute:(NSMutableArray *)array :(NSArray *)initial :(NSArray *)final
{
    NSArray *arrayCopy = [array copy];
    for (NSUInteger i = 0; i < [initial count]; i++)
        array[[initial[i] unsignedIntegerValue]] = arrayCopy[[final[i] unsignedIntegerValue]];
}

/*!
 * Permutes the order of some entries in the results dictionary for evaluateResults from an initial to final state.
 * @param results The results dictionary. Each value must be a mutable array of equal length.
 * @param initial Array of indices to reorder in the initial state.
 * @param final Array of the indices to replace those in initial with.
 */
- (void)permuteOrders:(NSDictionary *)results :(NSArray *)initial :(NSArray *)final
{
    for (id key in results)
        [self permute:results[key] :initial :final];
}

/*!
 * Permutes the order of all entries in the results dictionary for evaluateResults into a final state.
 * @param results The results dictionary. Each value must be a mutable array of equal length.
 * @param final Array of the final permutation of indices. Must be of the same length as each array in results.
 */
- (void)permuteOrders:(NSDictionary *)results :(NSArray *)final
{
    [self permuteOrders:results :[self range:[final count]] :final];
}

// Sorts the elements at indices in array, and returns those indices in sorted order.
- (NSArray *)indexSortedOrder:(NSArray *)array :(bool)ascending :(NSArray *)indices
{
    NSMutableArray *enumeration = [[NSMutableArray alloc] initWithCapacity:[indices count]];
    for (id idx in indices)
        [enumeration addObject:@{@"index": idx, @"value": array[[idx unsignedIntegerValue]]}];
    
//    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:ascending];
//    NSArray *sorted = [enumeration sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSArray *sorted = [enumeration sortedArrayWithOptions:NSSortStable usingComparator:
     ^NSComparisonResult(id obj1, id obj2)
     {
         if (ascending)
             return [obj1[@"value"] compare:obj2[@"value"]];
         else
             return [obj2[@"value"] compare:obj1[@"value"]];
     }];
    
    NSMutableArray *sortedIndices = [[NSMutableArray alloc] initWithCapacity:[indices count]];
    for (id pair in sorted)
        [sortedIndices addObject:pair[@"index"]];
    
    return [sortedIndices copy];
}
// Sorts an array and returns the sorting indices
- (NSArray *)indexSortedOrder:(NSArray *)array :(bool)ascending
{
    return [self indexSortedOrder:array :ascending :[self range:[array count]]];
}

// Returns an array of indices of elements in array (NSNumbers) where the condition block returns true
- (NSArray *)findIndices:(NSArray *)array :(bool (^)(NSNumber *))condition
{
    NSMutableArray *indices = [[NSMutableArray alloc] init];
    for (id idx in [self range:[array count]])
    {
        if (condition(array[[idx unsignedIntegerValue]]))
            [indices addObject:idx];
    }

    return [indices copy];
}

- (void)reorderBySpecMSE:(NSDictionary *)results
{
    NSLog(@"Reorder by MSE:");
    NSLog(@"%@\n%@", [self range:[results[@"specMSEs"] count]], [self indexSortedOrder:results[@"specMSEs"] :true]);
    
    [self permuteOrders:results :[self indexSortedOrder:results[@"specMSEs"] :true]];
}
- (void)reorderByMatchMismatchTau:(NSDictionary *)results :(float)mseThreshold :(float)strideThreshold :(float)matchWeight :(float)mismatchWeight :(float)tauWeight
{
    // 1. Of those that meet the MSE threshold, shuffle based on mismatch length
    bool (^withinMSEThreshold)(NSNumber *) = ^(NSNumber *num) {
        return (bool)([num floatValue] <= mseThreshold*[results[@"specMSEs"][0] floatValue]);
    };
    NSArray *initial0 = [self findIndices:results[@"specMSEs"] :withinMSEThreshold];    // These will be an ascending range from 0 to some number, since specMSEs have already been sorted in ascending order by a previous function
    
    // If empty, nothing more will happen, so just return
    if ([initial0 count] == 0)
        return;
    
    NSUInteger highestIndex0 = [[initial0 lastObject] unsignedIntegerValue];
    NSArray *final0 = [self indexSortedOrder:results[@"mismatchLengths"] :true :initial0];
    [self permuteOrders:results :initial0 :final0];
    
    
    // 2. Of those that were permuted in (1), and that also meet the stride threshold, reshuffle based on match length, mismatch length, and base lag value
    float stride = (float)self.fftLength / self.effectiveFramerate * (1 - self.overlapPercent/100);
    bool (^withinStrideThreshold)(NSNumber *) = ^(NSNumber *num) {
        return (bool)([num floatValue] <= strideThreshold * stride + [results[@"mismatchLengths"][0] floatValue]);
    };
    NSArray *rawInitial1 = [self findIndices:results[@"mismatchLengths"] :withinStrideThreshold];
    NSMutableArray *initial1 = [[NSMutableArray alloc] initWithCapacity:[rawInitial1 count]];    // These are the ones to be reshuffled
    for (id num in rawInitial1)
    {
        if ([num unsignedIntegerValue] <= highestIndex0)
            [initial1 addObject:num];
    }
    
    // Get the array of matchWeight * matchLength - mismatchWeight * mismatchLength + tauWeight * baseTau
    NSMutableArray *matchMismatchTau = [[NSMutableArray alloc] initWithCapacity:[results[@"matchLengths"] count]];
    for (NSUInteger i = 0; i < [results[@"matchLengths"] count]; i++)
    {
        float combo = matchWeight*[results[@"matchLengths"][i] floatValue] - mismatchWeight*[results[@"mismatchLengths"][i] floatValue] + tauWeight*[results[@"baseLags"][i] floatValue]/self.effectiveFramerate;
        [matchMismatchTau addObject:[NSNumber numberWithFloat:combo]];
    }
    
    // Reshuffle
    NSArray *final1 = [self indexSortedOrder:matchMismatchTau :false :initial1];
    [self permuteOrders:results :initial1 :final1];
    
    NSLog(@"Reorder by mismatch:");
    NSLog(@"%@\n%@", initial0, final0);
    NSLog(@"Reorder by match/mismatch/tau:");
    NSLog(@"%@\n%@", initial1, final1);
}
- (void)reorderBySlidingMSE:(NSDictionary *)results :(float)mseThreshold :(float)tauThreshold
{
    // Of those that meet the MSE threshold, shuffle based on both MSE values
    bool (^withinMSEThreshold)(NSNumber *) = ^(NSNumber *num) {
        return (bool)([num floatValue] <= mseThreshold*[results[@"specMSEs"][0] floatValue]);
    };
    
    // Get the array of slidingMSE * spectrumMSE
    NSMutableArray *mseProduct = [[NSMutableArray alloc] initWithCapacity:[results[@"specMSEs"] count]];
    for (NSUInteger i = 0; i < [results[@"specMSEs"] count]; i++)
    {
        float prod = [results[@"slidingMSEs"][i] floatValue] * [results[@"specMSEs"][i] floatValue];
        [mseProduct addObject:[NSNumber numberWithFloat:prod]];
    }
    
    // Shuffle only amongst groups of elements that are close together in lag value
    NSMutableArray *farElements = [[self findIndices:results[@"specMSEs"] :withinMSEThreshold] mutableCopy];    // These will no longer necessarily be an ascending range from 0 to some number, since things have been scrambled again.
    
    NSLog(@"Reorder by MSE product:");
    
    while ([farElements count] > 1)
    {
        bool (^withinTauThreshold)(NSNumber *) = ^(NSNumber *num) {
            return (bool)(fabsf([num floatValue] - [results[@"baseLags"][[farElements[0] unsignedIntegerValue]] floatValue]) <=  + tauThreshold*self.effectiveFramerate);
        };
        
        NSArray *close = [[self findIndices:results[@"baseLags"] :withinTauThreshold] mutableCopy];
        NSMutableArray *closeElements = [[NSMutableArray alloc] initWithCapacity:[close count]];
        // Use only elements originally in farElements. Also remove those elements from farElements itself afterwards.
        for (id idx in close)
        {
            if ([farElements containsObject:idx])
            {
                [closeElements addObject:idx];
                [farElements removeObject:idx];
            }
        }
        
        NSArray *reorderCloseElements = [self indexSortedOrder:mseProduct :true :closeElements];
        [self permuteOrders:results :closeElements :reorderCloseElements];
        NSLog(@"%@\n%@", closeElements, reorderCloseElements);
    }
}
// END HELPER HELPER FUNCTIONS //

// HELPER FUNCTIONS //

// Gets initial lag candidate values by running and minimizing the auto-sliding MSE, and inserts them into the results dictionary.
- (void)getInitialCandidates:(AudioDataFloat *)audio :(NSDictionary *)results
{
    // Frames in the sliding MSE to ignore from the left and right
    UInt32 sLeftIgnore = (UInt32)[self sanitizeInt:roundf(self.leftIgnore * self.effectiveFramerate) :roundf(self.minLoopLength * self.effectiveFramerate) :audio->numFrames];
//    MAX(0, MIN(audio->numFrames, roundf(self.leftIgnore * self.effectiveFramerate)));
    UInt32 sRightIgnore = (UInt32)[self sanitizeInt:roundf(self.rightIgnore * self.effectiveFramerate) :0 :audio->numFrames - sLeftIgnore];
//    MAX(0, MIN(audio->numFrames - sLeftIgnore, roundf(self.rightIgnore * self.effectiveFramerate)));
    
    float *autoMSE = malloc(audio->numFrames * sizeof(float));
    [self audioAutoMSE:audio :self.useMonoAudio :autoMSE]; // TAKES LOTS OF TIME
    NSArray *minIdx = [self spacedMinima:autoMSE+sLeftIgnore :audio->numFrames - sLeftIgnore - sRightIgnore :self.nBestDurations][@"indices"];  // TAKES A FAIR AMOUNT OF TIME
    
    for (id i in minIdx)
    {
        NSUInteger idx = sLeftIgnore + [i unsignedIntegerValue];
        [results[@"baseLags"] addObject:[NSNumber numberWithUnsignedInteger:idx]];
        [results[@"slidingMSEs"] addObject:[NSNumber numberWithFloat:*(autoMSE + idx)]];
    }
    free(autoMSE);
}

// Analyzes the initial lag candidates, fills out the rest (except confidence) of the results dictionary, and adjust the base lag values as necessary.
- (void)analyzeInitialCandidates:(AudioDataFloat *)audio :(NSDictionary *)results
{
    // Analyze each of the initial candidates
    for (id baseLag in results[@"baseLags"])
    {
        NSDictionary *analysisResults = [self analyzeLagValue:audio :[baseLag unsignedIntegerValue]];   // TAKES THE MOST TIME
        
        // Arrays
        [results[@"lags"] addObject:analysisResults[@"refinedLags"]];
        [results[@"startSamples"] addObject:analysisResults[@"startSamples"]];
        [results[@"sampleDiffs"] addObject:analysisResults[@"sampleDiffs"]];
        
        // Numbers
        [results[@"specMSEs"] addObject:analysisResults[@"spectrumMSE"]];
        [results[@"matchLengths"] addObject:analysisResults[@"matchLength"]];
        [results[@"mismatchLengths"] addObject:analysisResults[@"mismatchLength"]];
    }
    
    // Replace the base lags if possible with a more appropriate one
    for (NSUInteger i = 0; i < [results[@"lags"] count]; i++)
    {
        if ([results[@"lags"][i] count] > 0)
            results[@"baseLags"][i] = results[@"lags"][i][0];
    }
}

// Ranks the results dictionary for findLoopNoEst, and adds the confidence values
- (void)evaluateResults:(NSDictionary *)results
{
    // Internal parameters
    float mseThreshold = 2;
    float strideThreshold = 3;
    float matchWeight = 1;
    float mismatchWeight = 1;
    float tauWeight = 0.9;  // Tau is lag in seconds
    float tauThreshold = (float)self.fftLength / (2*self.effectiveFramerate);
    
    // Calculate confidence levels
    [results[@"confidences"] addObjectsFromArray:[self calcConfidence:results[@"specMSEs"]]];
    
    // Do each reordering step
    [self reorderBySpecMSE:results];
    [self reorderByMatchMismatchTau:results :mseThreshold :strideThreshold :matchWeight :mismatchWeight :tauWeight];
    [self reorderBySlidingMSE:results :mseThreshold :tauThreshold];
    
    // Restore descending confidence order
    NSSortDescriptor *sortDescending = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [results[@"confidences"] sortUsingDescriptors:@[sortDescending]];
}

// Generates the actual dictionary to return from findLoopNoEst, given its completed internal results dictionary
- (NSDictionary *)generateReturnDictionary:(NSDictionary *)results
{
    // Construct the end samples array of arrays
    NSMutableArray *endSamples = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [results[@"startSamples"] count]; i++)
    {
        NSMutableArray *ends = [[NSMutableArray alloc] init];   // For a single base lag value
        for (NSUInteger j = 0; j < [results[@"startSamples"][i] count]; j++)
        {
            NSUInteger end = [results[@"startSamples"][i][j] unsignedIntegerValue] + [results[@"lags"][i][j] unsignedIntegerValue];
            [ends addObject:[NSNumber numberWithUnsignedInteger:end]];
        }
        
        [endSamples addObject:[ends copy]];
    }
    
    return @{@"baseDurations": [results[@"baseLags"] copy],
             @"startFrames": [results[@"startSamples"] copy],
             @"endFrames": [endSamples copy],
             @"confidences": [results[@"confidences"] copy],
             @"sampleDifferences": [results[@"sampleDiffs"] copy]
             };
}

// END HELPER FUNCTIONS //

- (NSDictionary *)findLoopNoEst:(AudioDataFloat *)audio
{
    NSDictionary *results = @{@"baseLags": [[NSMutableArray alloc] init],
                              @"slidingMSEs": [[NSMutableArray alloc] init],
                              @"specMSEs": [[NSMutableArray alloc] init],
                              @"startSamples": [[NSMutableArray alloc] init],
                              @"sampleDiffs": [[NSMutableArray alloc] init],
                              @"lags": [[NSMutableArray alloc] init],
                              @"matchLengths": [[NSMutableArray alloc] init],
                              @"mismatchLengths": [[NSMutableArray alloc] init],
                              @"confidences": [[NSMutableArray alloc] init]
                              };   // To hold all the results as they come
    
    [self getInitialCandidates:audio :results]; // Lots of time
    [self analyzeInitialCandidates:audio :results]; // Most time
    [self evaluateResults:results];
    return [self generateReturnDictionary:results];
}


// HELPER FUNCTIONS //
- (NSDictionary *)getInitialCandidatesWithEst:(AudioDataFloat *)audio :(float)forwardProportion
{
    // Returns a dictionary with the candidate "baseLags" and "confidences"
    
    UInt32 forwardSamples = roundf(self.minLoopLength * self.effectiveFramerate * forwardProportion);
    UInt32 backSamples = roundf(self.minLoopLength * self.effectiveFramerate * (1 - forwardProportion));
    
    UInt32 sampleStart1 = 0;
    UInt32 sampleEnd1 = 0;
    UInt32 sampleStart2 = 0;
    UInt32 sampleEnd2 = 0;
    
    if ([self hasT1Estimate])
    {
        sampleStart1 = (UInt32)[self sanitizeInt:(NSInteger)[self s1Estimate]-backSamples :0 :audio->numFrames-1];
        sampleEnd1 = (UInt32)[self sanitizeInt:[self s1Estimate]+forwardSamples :0 :audio->numFrames-1];
    }
    if ([self hasT2Estimate])
    {
        sampleStart2 = (UInt32)[self sanitizeInt:(NSInteger)[self s2Estimate]-backSamples :0 :audio->numFrames-1];
        sampleEnd2 = (UInt32)[self sanitizeInt:[self s2Estimate]+forwardSamples :0 :audio->numFrames-1];
    }
    
    if ([self loopMode] == loopModeT1Only)
    {
        sampleStart2 = (UInt32)[self sanitizeInt:sampleEnd1+1 :0 :audio->numFrames-1];
        sampleEnd2 = audio->numFrames - 1;
    }
    else if([self loopMode] == loopModeT2Only)
    {
        sampleStart1 = 0;
        sampleEnd1 = (UInt32)[self sanitizeInt:sampleStart2 :1 :audio->numFrames] - 1;
    }
    
    UInt32 nMSE = sampleEnd1-sampleStart1 + sampleEnd2-sampleStart2 + 1;
    float *slidingMSEs = malloc(nMSE * sizeof(float));
    [self audioMSE:audio :self.useMonoAudio :sampleStart2 :sampleEnd2 :sampleStart1 :sampleEnd1 :slidingMSEs];
    
    UInt32 sLeftIgnore = roundf(self.leftIgnore * self.effectiveFramerate);
    UInt32 sRightIgnore = roundf(self.rightIgnore * self.effectiveFramerate);
    
    NSArray *tauLims = [self tauLimits:audio->numFrames];
    UInt32 minLag = MAX(ceilf([tauLims[0] floatValue]*self.effectiveFramerate), sLeftIgnore);
    UInt32 maxLag = (UInt32)[self sanitizeInt:floorf([tauLims[1] floatValue]*self.effectiveFramerate) :0 :(NSInteger)audio->numFrames-1-sRightIgnore];
    
    
    // Indices of valid lags must be >= minLagIdx and <= maxLagIdx
    NSInteger minLagIdx = MAX(0, (NSInteger)minLag - ((NSInteger)sampleStart2 - sampleEnd1));
    NSInteger maxLagIdx = MIN((NSInteger)nMSE - 1, (NSInteger)maxLag - ((NSInteger)sampleStart2 - sampleEnd1));
    UInt32 nValidLags = (UInt32)[self sanitizeInt:maxLagIdx-minLagIdx+1 :0 :nMSE];
    
    // Weighting by distance from estimated lag
    if ([self loopMode] == loopModeT1T2 && self.tauPenalty != 1 && self.tauPenalty != 0)
    {
        float tauEstimate = [self t2Estimate] - [self t1Estimate];
        
        for (NSInteger i = 0; i < nValidLags; i++)
        {
            *(slidingMSEs+minLagIdx + i) *= 1.0 + [self slopeFromPenalty:self.tauPenalty]*fabsf((float)(minLag + i) / self.effectiveFramerate - tauEstimate);
        }
    }
    
    NSDictionary *minMSEs = [self spacedMinima:slidingMSEs+minLagIdx :nValidLags :self.nBestDurations];
    free(slidingMSEs);
    
    // Calculate the confidence levels
    float regularization = 0.1; // MESS WITH THIS?
    NSArray *confidences = [self calcConfidence:minMSEs[@"values"] :regularization];
    
    // Turn the indices into the lag values they represent
    NSMutableArray *baseLags = [minMSEs[@"indices"] mutableCopy];
    for (NSUInteger i = 0; i < [baseLags count]; i++)
        baseLags[i] = [NSNumber numberWithUnsignedInteger:[baseLags[i] unsignedIntegerValue] + minLag + i];
    
    return @{@"baseLags": [baseLags copy], @"confidences": confidences};
}
- (NSDictionary *)analyzeInitialCandidatesWithEst:(AudioDataFloat *)audio :(NSArray *)baseLags
{
    // Returns a dictionary with the arrays of arrays for initial candidate analysis results: "lags", "starts", "ends", and "sampleDiffs"
    
    NSArray *t1Lims = [self t1Limits:audio->numFrames];
    NSArray *t2Lims = [self t2Limits:audio->numFrames];
    
    NSMutableArray *lags = [[NSMutableArray alloc] initWithCapacity:[baseLags count]];
    NSMutableArray *startSamples = [[NSMutableArray alloc] initWithCapacity:[baseLags count]];
    NSMutableArray *sampleDiffs = [[NSMutableArray alloc] initWithCapacity:[baseLags count]];
    for (id baseLag in baseLags)
    {
        NSInteger firstStart = [self sanitizeInt:ceilf([t1Lims[0] floatValue]*self.effectiveFramerate) :ceilf([t2Lims[0] floatValue]*self.effectiveFramerate) - [baseLag integerValue] :ceilf([t1Lims[1] floatValue]*self.effectiveFramerate)];
        NSInteger lastStart = [self sanitizeInt:floorf([t1Lims[1] floatValue]*self.effectiveFramerate) :0 :floorf([t2Lims[1] floatValue]*self.effectiveFramerate) - [baseLag integerValue]];
        NSUInteger nStarts = MAX(0, lastStart - firstStart + 1);
        NSUInteger *starts = 0;
        
        if (nStarts > 0)
        {
            starts = malloc(nStarts * sizeof(NSUInteger));
            for (NSUInteger i = 0; i < nStarts; i++)
                *(starts + i) = firstStart + i;
        }
        
        NSDictionary *pairs = [self findEndpointPairs:audio :[baseLag unsignedIntegerValue] :starts :nStarts];
        [lags addObject:pairs[@"lags"]];
        [startSamples addObject:pairs[@"starts"]];
        [sampleDiffs addObject:pairs[@"sampleDiffs"]];
        
        if (nStarts > 0)
            free(starts);
    }
    
    // Calculate end samples
    NSMutableArray *endSamples = [[NSMutableArray alloc] initWithCapacity:[startSamples count]];
    for (NSUInteger i = 0; i < [startSamples count]; i++)
    {
        NSMutableArray *ends = [[NSMutableArray alloc] initWithCapacity:[startSamples[i] count]];
        for (NSUInteger j = 0; j < [startSamples[i] count]; j++)
            [ends addObject:[NSNumber numberWithUnsignedInteger:[startSamples[i][j] unsignedIntegerValue] + [lags[i][j] unsignedIntegerValue]]];
        
        [endSamples addObject:ends];
    }
    
    return @{@"lags": [lags copy],
             @"starts": [startSamples copy],
             @"ends": [endSamples copy],
             @"sampleDiffs": [sampleDiffs copy]
             };
}
// END HELPER FUNCTIONS //
- (NSDictionary *)findLoopWithEst:(AudioDataFloat *)audio
{
    float forwardProportion = 0.9;  // Internal value for the amount of the minLoopLength window to spend looking forward in time
    NSDictionary *candidates = [self getInitialCandidatesWithEst:audio :forwardProportion];
    NSDictionary *analysis = [self analyzeInitialCandidatesWithEst:audio :candidates[@"baseLags"]];
    
    
    return @{@"baseDurations": candidates[@"baseLags"],
             @"startFrames": analysis[@"starts"],
             @"endFrames": analysis[@"ends"],
             @"confidences": candidates[@"confidences"],
             @"sampleDifferences": analysis[@"sampleDiffs"]
             };
}

@end
