# Loop Finder Algorithms

This page discusses the algorithms used by the automatic Loop Finder. **For an overview of the key ideas behind the algorithms, see the [core techniques](loopfinder_algorithms_core_techniques.md) page**. The algorithm descriptions assume familiarity with the core techniques, so make sure to read through that page first if you haven't already!

Broadly, the Loop Finder has two modes, each with a separate algorithm:

1. [Without any initial estimates](#without-initial-estimates)
2. [With at least one initial estimate](#with-initial-estimates)

Each mode is described in its own section.

## Preprocessing

The Loop Finder performs some preprocessing steps before performing the bulk of the analysis. These steps are common to both modes.

1. [NOT IMPLEMENTED] If configured, detect if the end of the track has a fade applied to it, and if so, truncate the faded part.
2. Reduce the frame rate of the audio by the configured [*Frame Rate Reduction*](loopfinder_settings.md#performance-settings) factor by downsampling. This can drastically improve performance without sacrificing much quality.
3. Make sure the audio file isn't longer than a specified [*Track Length Limit*](loopfinder_settings.md#performance-settings) (this is to control memory usage). If it is, try reducing the frame rate by even more, but only up to a configured [*Frame Rate Reduction Limit*](loopfinder_settings.md#performance-settings). If the audio file is still too long even after the maximum allowable frame rate reduction, just truncate the audio.
    - Under the default settings, truncation happens for tracks longer than about 8 minutes long, assuming a typical 44.1 kHz sample rate. The length can be extended by increasing the *Frame Rate Reduction Limit*, although this might lead to results of poorer quality.

## Without Initial Estimates

### Overview

Since little information is given about the loop, the Loop Finder proceeds in a multistage process to make and refine its estimates. The stages can be summarized as:

1. [Identify the most promising candidates for loop duration value.](#loop-duration-estimation)
2. [For each of the loop duration candidates, infer the most likely loop region.](#loop-region-inference)
3. [Using knowledge of the loop region, refine the loop duration values.](#loop-duration-refinement)
4. [For each loop duration value, identify the best loop endpoints.](#loop-endpoint-selection)
5. [Rank the loop duration values from most promising to least promising.](#loop-duration-ranking)

Each of these steps is described in more detail in the subsections that follow.

### Loop Duration Estimation

Initial estimates for loop duration are located using a [normalized auto-MSE](loopfinder_algorithms_core_techniques.md#normalized-cross-mse).

1. As an additional preprocessing step, remove configurable amounts of time from the start and end of the waveform ([*Start Ignore*](loopfinder_settings.md#duration-search-restrictions) and [*End Ignore*](loopfinder_settings.md#duration-search-restrictions), respectively). This can improve the auto-MSE by cutting out unique sections of audio in intros and outros.
2. Compute the normalized auto-MSE of the truncated waveform.
3. Select candidate loop durations one at a time, up to a number specified by [*Duration Values*](loopfinder_settings.md#output-settings). Perform selection by locating the lag value for which the auto-MSE is minimized, while requiring each new candidate to be:
    1. Longer than the [*Minimum Duration*](loopfinder_settings.md#duration-search-restrictions).
    2. At least a distance of [*Duration Separation*](loopfinder_settings.md#duration-search-restrictions) away from all previous candidates (non-maximum suppression).

### Loop Region Inference

The most likely loop region for a given loop duration is inferred using a combination of [spectral analysis techniques](loopfinder_algorithms_core_techniques.md#spectral-analysis-techniques). The below steps are repeated for each loop duration candidate.

1. Compute [spectrograms](loopfinder_algorithms_core_techniques.md#spectrograms) for the audio and its lagged counterpart, using the configured [*FFT Length*](loopfinder_settings.md#spectrogram-settings) and [*Overlap Percentage*](loopfinder_settings.md#spectrogram-settings).
2. Compute the [spectrum MSE](loopfinder_algorithms_core_techniques.md#spectrum-mse) for each pair of corresponding windows within the spectrograms.
3. Calculate an initial cutoff value (explained shortly) as follows:
    1. Calculate the median of the **n** smallest spectrum MSE values across windows, where **n** is the number of windows needed to span a region as long as the *Minimum Duration*.
    2. Take twice the difference between the calculated median and the minimum spectrum MSE value, and add this to minimum spectrum MSE value to get the cutoff.
4. Find the first and last windows with spectrum MSEs not exceeding the cutoff. Use the corresponding times as initial estimates for the loop region bounds.
5. If no windows meet the cutoff, or if the resulting loop region is shorter than the *Minimum Duration*, repeat the following steps to gradually raise the cutoff until an acceptable loop region is found:
    1. If **n** (from the initial cutoff calculation) is less than the total number of windows, increment **n** by 1 and repeat the cutoff calculation. Otherwise, set the cutoff to the smallest spectrum MSE value that exceeds the current cutoff.
    2. Recalculate the loop region bounds with the new cutoff.

#### Match and Mismatch Lengths

At this point, the loop region bounds have been determined. These next few steps are taken to calculate the "match length" and "mismatch length", which are used later in the [ranking step](#loop-duration-ranking).

1. Modify (usually loosen) the cutoff by taking the largest of the following three quantities:
    1. **Cutoff 1** is designed for when the MSEs span a large range of values. It will generally be above the small values, but below the large values.
        1. Ignore the largest 5% of the spectrum MSE values. Calculate the median of the **N** largest remaining spectrum MSE values, where **N** is either the number of windows needed to span a region as long as the *Minimum Duration*, or 5% the total number of windows; whichever is larger.
        2. Take 5% the difference between the median calculated in the previous step and the median of the smallest **n** spectrum MSE values (the value of **n** *after* an acceptable loop region was found). Add this to the median of the smallest **n** spectrum MSE values to get **cutoff 1**.
    2. **Cutoff 2** is designed for when the MSEs are all very small with low variability. It will generally be higher than all the low values.
        1. Calculate the mean, median, and standard deviation of the spectrum MSEs for windows within the loop region.
        2. Take the smaller of the mean and the median just calculated, and subtract the minimum spectrum MSE. This is the *base value*.
        3. Divide 5 by the standard deviation, but confine the value between 1 and 5. This is the *base multiplier*.
        4. Multiply the base value by the base multiplier, then add this value to the minimum spectrum MSE to get **cutoff 2**.
    3. **Cutoff 3** is always 2.5. It prevents the cutoff from becoming too tight.
2. Compute the match length by summing the effective durations (durations minus the overlap with neighboring windows) of all windows whose spectrum MSE does not exceed the new cutoff. The match length is roughly representative of the duration of the loop region, but not exactly the same.
3. Compute the mismatch length by summing the effective durations of all windows that are *outside of the loop region* and whose spectrum MSE exceeds the new cutoff. The mismatch length is roughly representative of the duration of time for which the audio and its lagged counterpart are overlapping but not the same.

### Loop Duration Refinement

Once the loop region is known, the initial estimates of loop duration can be refined. The below steps are repeated for each loop duration candidate.

1. Splice out just the loop region of the audio. Do the same with the lagged loop region (the repeated part after the first loop). Take the normalized cross-MSE between these two regions.
2. Search through lag values that are within a half *Duration Separation* of the initial loop duration estimate. Out of these lag values, use the one that minimizes the cross-MSE as the refined loop duration.

### Loop Endpoint Selection

Once both the loop duration and the loop region have been identified, loop endpoints can be found by comparing the raw audio waveform at different points. The below steps are repeated for each loop duration candidate.

1. Identify the spectrogram window with the smallest spectrum MSE.
2. For each point in the window, compare it with the corresponding point in the lagged window by taking the absolute difference between the two samples (the *sample difference*).
3. Create the *initial endpoint pair list* by searching through the sample differences and favoring the smallest ones. Only add up to a maximum number of pairs specified by the [*Endpoint Pairs*](loopfinder_settings.md#output-settings) setting.
4. Remove any endpoint pairs whose sample difference exceeds the [*Endpoint Difference Tolerance*](loopfinder_settings.md#endpoint-search-restrictions).
5. If the filtered endpoint pair list has the maximum number of *Endpoint Pairs*, endpoint selection is complete. Otherwise, continue to the next step.
6. Attempt to add more endpoint pairs to the initial list by perturbing the loop duration by a small amount:
    1. Iterate through lag values by "spiraling away" from the original value. I.e., if the original lag (as a sample count) is **x** samples, iterate through **x+1**, **x-1**, **x+2**, **x-2**, and so on. Make sure that the lag value doesn't fall below the *Minimum Duration* and doesn't exceed the total length of the audio track.
    2. For each modified lag value **x+dx**, try shifting the non-lagged window by **-dx**, and also try shifting the lagged window by **dx**. For both of these possibilities, add endpoint pairs to the list with the same procedure that was used to create the initial list.
    3. Continue spiraling away from the original lag until one of the following conditions is met:
        1. The magnitude of **dx** exceeds half of the *Duration Separation* setting.
        2. No satisfactory endpoint pairs were found under the modified lag value.
        2. There are no more valid lag values to try.
7. If the final endpoint pair list is empty, but the initial endpoint pair list (before filtering) has at least one entry, select the first entry from the initial list.
8. If both lists are empty, loop endpoint selection fails.

### Loop Duration Ranking

Once all the loop durations and their corresponding loop endpoints have been determined, all that remains is to rank the loop durations from most to least promising. This is done in four passes. Following ranking, loop finding is complete.

#### Preparation

Before ranking, some quantities need to be computed.

1. For each loop duration, compute the *biased mean spectrum MSE*, **µ**, defined as the mean of the lowest 90% of spectrum MSEs across all windows in the spectrogram. Filtering out the highest 10% makes **µ** more robust in the presence of brief bouts of noisiness in the original audio signal.
2. For each loop duration, compute a *weight value*, **w = [(_e_<sup>µ</sup> - 1) + (_e_<sup>r</sup> - 1)]<sup>-1</sup>**, where **r = 2.5** is a regularization parameter. This formula was chosen empirically because **w** is roughly constant for low values of **µ** and exponentially decaying for high values of **µ**.
3. Normalize each weight by the sum of all the weights. These normalized weights are the *confidence values*.

#### Four-Pass Ranking

1. **Pass 1**: Sort the loop durations in ascending order of **µ**.
2. **Pass 2**: Of the loop durations whose corresponding **µ** value does not exceed twice the smallest **µ** value, sort in ascending order of *mismatch length*. This takes all the decent loop duration values and favors those that have smaller non-repeating sections.
3. **Pass 3**: Of the loop durations that were sorted in the previous pass *and* whose mismatch lengths do not exceed the current list head's mismatch length by more than 3 effective window sizes (from the spectrogram), sort in descending order by the metric **∆ = (match length) - (mismatch length) + 0.9 × (loop duration)**. This takes all the decent loop duration values that have reasonably small non-repeating sections and favors those that have longer loop regions closer to the end of the audio file.
4. **Pass 4**: Of the loop durations whose corresponding **µ** value does not exceed twice the current list head's **µ** value (not necessarily the smallest anymore):
    1. Partition the selected elements into subgroups of similar loop duration value. Build subgroups one at a time with the following procedure:
        1. Take the elements that do not already belong to a subgroup, preserving order. Call this subarray **s**.
        2. Make a new subgroup containing elements in **s** whose loop durations do not exceed the loop duration of **s[0]** (the first element of **s**) by more than half the window size (from the spectrogram). Note that the *actual* window size should be used, not the effective one.
    2. Within each subgroup, permute the elements in ascending order by the product of their normalized auto-MSE and **µ** values. This takes all the decent loop durations and favors those that have good results from both direct waveform analysis and from spectral analysis, but without scrambling elements that are qualitatively different (meaning the difference in loop durations can be resolved by the spectrogram window size).
5. After all the passes have been completed, the confidence values may no longer be in descending order. Sort *just* the confidence values in descending order. Note that this may scramble the confidence values with respect to the loop durations originally used to compute them.

## With Initial Estimates

### Overview

Initial estimates provide a great deal of information. As such, the algorithm for this mode is significantly simpler than the no-estimate mode. Loop finding involves two stages:

1. [Identify the most promising candidates for loop duration value.](#loop-duration-estimation-1)
2. [For each loop duration value, identify the best loop endpoints.](#loop-endpoint-selection-1)

The algorithm proceeds similarly regardless of whether a start estimate, end estimate, or both are provided; there are only a few technical differences related to enforcing different constraints.

### Loop Duration Estimation

1. Determine two snippets of audio (a contiguous subset of the full audio) for comparison, with one containing the loop start (the "start snippet") and one containing the loop end (the "end snippet").
    - If a start (end) estimate was provided, the start (end) snippet is an asymmetric interval around the start (end) estimate. The interval has a length equal to the [*Minimum Duration*](loopfinder_settings.md#duration-search-restrictions), 10% of which is audio before the estimate and 90% of which is audio after the estimate.
    - If no end estimate was provided, the end snippet is set to the audio region between the start snippet and the end of the full audio track.
    - If no start estimate was provided, the start snippet is set to the audio region between the beginning of the audio track and the end snippet.
2. Compute the normalized cross-MSE between the start and end snippets. Remove lag values that are less than the [*Start Ignore*](loopfinder_settings.md#duration-search-restrictions) setting or greater than the track duration minus the [*End Ignore*](loopfinder_settings.md#duration-search-restrictions) setting.
3. If *both* a start and end estimate were provided, calculate the base lag estimate **∆t** as the difference between the two estimates. Multiply the normalized cross-MSE values by specific weights in order to penalize deviation from this base estimate. To determine the multipliers:
    1. Compute a slope value **m**. If the [*Loop Duration Estimate Deviation Penalty*](loopfinder_settings.md#estimate-deviation-penalties) is **p**, then **m = tan(p × π/2)**. The penalty **p** can be thought of as controlling the angle of a line, with **p = 0** being horizontal and **p = 1** being vertical.
    2. If the [*Loop Duration Estimate Window Radius*](loopfinder_settings.md#estimate-window-radii) is **R**, then the multiplier for a given lag value **l** is **w = 1 + m × |l - ∆t|** if both **w ≤ 2** *and* **|l - ∆t| ≤ R**, or infinity otherwise. In other words, if the multiplier gets too high (>2) or the lag deviates too far (>R), that lag value should not be considered as a potential candidate.
4. Build a list of loop duration candidates using [the same procedure as in no-estimate mode](#loop-duration-estimation), using the normalized cross-MSE rather than the normalized auto-MSE. Additionally, do not enforce the *Minimum Duration* constraint; in no-estimate mode this constraint is primarily to prevent a lag of zero being selected, but the problem is already avoided here because of the way the start and end snippets are selected.
5. Compute confidence values for each loop duration candidate. Use [the same formula for the weights as in no-estimate mode](#preparation), except using the normalized cross-MSE values for **µ** and **r = 0.1** for regularization.

### Loop Endpoint Selection

Loop endpoint selection in estimate mode is almost identical to [loop endpoint selection in no-estimate mode](#loop-endpoint-selection), with the following differences:

1. There are no spectrograms to pick windows from, so all endpoint pairs separated by the given lag value start out as potential candidates (some could be filtered out in the next step).
2. Multiply all sample differences by specific weights in order to penalize endpoints that deviate from their estimates. The multipliers are computed analogously to the lag multipliers during [Loop Duration Estimation](#loop-duration-estimation-1), except using the [*Start/End Time Estimate Deviation Penalties*](loopfinder_settings.md#estimate-deviation-penalties) and the [*Start/End Time Estimate Window Radii*](loopfinder_settings.md#estimate-window-radii). If only one estimate was provided, use the multipliers for that endpoint. If both start and end estimates were provided, the total multiplier for a given sample difference is the product of the multipliers for each endpoint.

Following loop endpoint selection, loop finding is complete.

## Miscellaneous Notes

- In the algorithms described above, it is assumed that audio is represented in floating-point format with waveform values normalized between -1 and 1. Under other normalizations, parameters will need to be retuned accordingly.
- In the above descriptions, the terms "lag" and "loop duration" are used interchangeably.
- The no-estimate mode works best if the track has at least 5-10 seconds of non-faded post-loop repetition. If there is less than 5 seconds of non-faded post-loop repetition, the initial loop duration might be estimated poorly, leading to incorrect results; in such cases, it is better to provide initial estimates.
- Despite the precise formula, the confidence values computed by the Loop Finder are not particularly meaningful. They should only be used to gauge if a few of the loop durations are vastly better than the rest, or if the results are all similarly good.