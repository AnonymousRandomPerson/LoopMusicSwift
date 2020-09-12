# Loop Finder Settings

## Initial Estimate Settings

These settings are only used if at least one initial estimate is provided to the Loop Finder.

### Estimate Window Radii

- *Start Time Estimate Window Radius*: The maximum amount of time in seconds by which loop start times are allowed to differ from the start time estimate, if one was provided.
- *End Time Estimate Window Radius*: The maximum amount of time in seconds by which loop end times are allowed to differ from the end time estimate, if one was provided.
- *Loop Duration Estimate Window Radius*: The maximum amount of time in seconds by which loop durations are allowed to differ from the estimated loop duration, if both start and end time estimates were provided.

### Estimate Deviation Penalties

See the [Loop Finder Algorithms](loopfinder_algorithms.md) page for more details on how deviation penalties are applied.

- *Start Time Estimate Deviation Penalty*: A value between 0 and 1 indicating how strongly to penalize deviation of loop start times from the start time estimate, if one was provided. A value of 0 indicates no penalty for deviations, while a value of 1 indicates that no deviation is allowed.
- *End Time Estimate Deviation Penalty*: A value between 0 and 1 indicating how strongly to penalize deviation of loop end times from the end time estimate, if one was provided. A value of 0 indicates no penalty for deviations, while a value of 1 indicates that no deviation is allowed.
- *Loop Duration Estimate Deviation Penalty*: A value between 0 and 1 indicating how strongly to penalize deviation of loop durations from the esimated loop duration, if both start and end time estimates were provided. A value of 0 indicates no penalty for deviations, while a value of 1 indicates that no deviation is allowed.

## Internal Settings

### Duration Search Restrictions

- *Minimum Duration*: The minimum allowable loop duration in seconds.
    - If initial estimates are provided to the Loop Finder, this setting is used slightly differently. Additionally, this setting is used internally in a variety of other contexts. See the [Loop Finder Algorithms](loopfinder_algorithms.md) page for more details.
- *Duration Separation*: The minimum amount of time in seconds by which all loop durations must differ from each other.
    - This setting is also used in a few other contexts. See the [Loop Finder Algorithms](loopfinder_algorithms.md) page for more details.
    - This setting is useful for ensuring that all loop duration returned by the Loop Finder are qualitatively different, which increases the chance that at least one of them will be correct.
    - If the Loop Finder is finding loop durations that are slightly off from the correct value (differ by less than the value of this setting), reducing this setting could help stop the Loop Finder from suppressing the correct loop duration in favor of the slightly off loop duration.
- *Start Ignore*: The amount of time in seconds at the start of the audio track to throw out before searching for loops.
    - This is useful for removing intros from an audio track, which could be detrimental to the Loop Finder.
- *End Ignore*: The amount of time in seconds at the end of the audio track to throw out before searching for loops.
    - This is useful for removing fades and outros from an audio track, which could be detrimental to the Loop Finder.
- *Fade Detection*: Whether or not the Loop Finder should try to detect and remove fade-out sections at the end of the audio track as a preprocessing step.
    - Note that since fade detection is not yet implemented, this setting currently has no effect.

### Endpoint Search Restrictions

- *Endpoint Difference Tolerance*: The maximum allowable absolute difference between the start and end samples of a loop.
    - Decreasing this value could lead to more seamless loops, but decreasing it too much could cause the Loop Finder to return no results.

### Spectrogram Settings

- *FFT Length*: The number of samples to use for each window in spectrogram calculations.
    - Divide this number by the sampling frequency of the audio file (in Hz) to get the window size in seconds.
    - Decreasing the window size will increase the time resolution of spectrograms, but also make each window noisier. It might also make the Loop Finder run slightly faster.
- *Overlap Percentage*: The percent overlap between adjacent spectrogram windows. This value should be nonnegative and less than 100.
    - Increasing the overlap percentage is a way to effectively increase the time resolution of spectrograms without sacrificing the quality of individual windows (like when decreasing the window size), but will also make the Loop Finder run slower.

## Performance Settings

- *Use Mono Audio*: If this setting is enabled, mono audio will be used instead of stereo data for all parts of analysis except for [sample differencing](loopfinder_algorithms_core_techniques.md#sample-differencing) (used for selecting loop endpoint pairs, see the [Loop Finder Algorithms](loopfinder_algorithms.md) page).
    - This will make the Loop Finder about twice as fast.
    - While the quality of results is usually not affected, you can try disabling this setting if you want to maximize accuracy.
- *Frame Rate Reduction*: If set to **x**, the Loop Finder will reduce the frame rate of audio by a factor of **x** before doing analysis.
    - This will make the Loop Finder about **x** times as fast. If you want the Loop Finder to run faster, you can try increasing this setting.
    - The quality of results is usually not affected for low values of **x**, but empirically, values of 7 or higher can sometimes cause instability in the algorithm. If you are having problems with accuracy, you can try reducing this setting (but be aware that if the audio track longer than the track length limit, the Loop Finder may use a frame rate reduction factor above the configured value).
- *Frame Rate Reduction Limit*: The maximum allowable frame rate reduction factor.
    - For tracks that exceed the track length limit, the Loop Finder will attempt to reduce the frame rate until the track is short enough, but it will never exceed the *Frame Rate Reduction Limit* and will instead resort to truncation once the frame rate reduction limit is reached.
- *Track Length Limit*: The maximum number of raw samples that the Loop Finder will analyze.
    - If a track's sample count exceeds this value, the Loop Finder will force sample count under the limit by reducing the framerate (up to the *Frame Rate Reduction Limit*), and then truncating as a last resort.
    - The default value is **2<sup>21</sup>**. Together with the default *Frame Rate Reduction Limit* of 10, this limits the length of a typical 44.1 kHz audio track to about 8 minutes.

## Output Settings

- *Duration Values*: The maximum number of base duration values the automatic Loop Finder will return.
- *Endpoint Pairs*: The maximum number of endpoint pairs per base duration the automatic Loop Finder will return.

## Testing Settings

- *Test on Change*: If this setting is enabled, loops will be tested (playback will be set close to the loop end, as if the "Test Loop" button had been pressed) automatically whenever loop points are changed.
- *Loop Test Offset*: If set to **x**, pressing the "Test Loop" button will set playback to **x** seconds before the loop end.