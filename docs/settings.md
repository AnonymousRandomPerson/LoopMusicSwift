# LoopMusic Settings

## General Settings

- *Play on App Start*: If this setting is enabled, a random song in the current playlist will be played automatically upon starting the app. Otherwise, no song will be selected upon startup and a track must be selected manually.
- *Master Volume*: A multiplier between 0 and 1 for the audio waveforms of all tracks played by the app. This can be used to adjust the volume of music playback relative to audio from other apps.
- *Default Relative Volume*: Specifies the *Relative Volume* setting (see [Track Settings](#track-settings)) to use for any tracks LoopMusic has not seen before.

## Track Settings

- *Relative Volume*: A multiplier between 0 and 1 for the audio waveform of the currently selected track. This multiplier is applied on top of the *Master Volume* (i.e., the two values are multiplied together). This can be used to adjust the volume of the current track relative to other tracks.
- *Normalize to __x__ dB*: Automatic volume normalization. Behavior varies depending on whether or not **x** is specified.
    - If **x** is set, clicking "Go!" will compute the *Relative Volume* needed in order to make the track's average volume **x** decibels. The *Relative Volume* setting will then be set to the calculated value (capped to the maximum value of 1).
        - Average volume is defined as the decibel value corresponding to the average squared amplitude of the audio waveform. I.e., if the raw waveform is **y[t]** and the *Relative Volume* multiplier is **r**, the average volume is **10 × log<sub>10</sub>[&lt;(r × y)<sup>2</sup>&gt; × 10<sup>12</sup>]**.
        - Decibel values in absolute terms are calculated assuming the *Master Volume* is 1 and the system is playing at maximum volume.
    - If **x** is not set, clicking "Go!" will set **x** to the average volume of the track under the current *Relative Volume* setting.

## Shuffle Settings

- *Fade Duration*: If set to **x**, songs will fade out over **x** seconds before a shuffle. If not set, transitions will occur without fading.
- *History Length*: If set to **x**, your track history will be **x** tracks long.
    - You will be able to scroll back through the last **x** songs.
    - When shuffling, LoopMusic will try not to pick any of the last **x** songs. If this is not possible, it will instead just try to pick a song different than the most recent one. If even this is not possible, it will fall back to picking anything from the full playlist.
    - If you decrease **x** from its previous value, entries that no longer fit into the new track history length will be dropped, starting from the oldest entry.
- *Shuffle Mode*: How LoopMusic will determine when to shuffle automatically to a new track.
    1. **None**: Never shuffle automatically. The current track will never change until you select a new one manually.
    2. **Time**: Shuffle after a certain amount of time, subject to the [Time Shuffle Settings](#time-shuffle-settings).
    3. **Repeats**: Shuffle after a certain number of repeats, subject to the [Repeats Shuffle Settings](#repeats-shuffle-settings).
        - A "repeat" is defined as the length of time between the song's loop endpoints (the "loop duration"), corrected for the "introduction" period before the loop's starting point. For example, one repeat is the length of time it takes for the song to play from the beginning to the end of the loop, while two repeats is the length of one repeat plus an additional loop duration.

### Time Shuffle Settings

- *Shuffle Time*: The base amount of time in minutes for which a single song will play before shuffling. This is only a base value; it can be modified further depending on other Time Shuffle Settings.
- *Shuffle Time Variance*: The maximum proportion of the base shuffle time that can be added or subtracted when calculating the actual shuffle time. More precisely, if *Shuffle Time* is set to *T* and *Shuffle Time Variance* is set to **p**, then the actual shuffle time will be a random value (drawn uniformly) between **(1-p)T** and **(1+p)T**.
- *Minimum Shuffle Repeats*: If this value is set, then the base *Shuffle Time* must run for at least this many repeats in a given song. If the *Shuffle Time* is too short, then the specified repeat duration will replace the configured *Shuffle Time* in the *Shuffle Time Variance* calculation.
- *Maximum Shuffle Repeats*: If this value is set, then the base *Shuffle Time* cannot run longer than this many repeats in a given song. If the *Shuffle Time* is too long, then the specified repeat duration will replace the configured *Shuffle Time* in the *Shuffle Time Variance* calculation.

### Repeats Shuffle Settings

- *Shuffle Repeats*: The base number of repeats for which a single song will play before shuffling. This is only a base value; it can be modified further depending on other Repeats Shuffle Settings.
- *Shuffle Repeats Variance*: The maximum proportion of the base shuffle repeats that can be added or subtracted when calculating the actual shuffle repeats. More precisely, if *Shuffle Repeats* is set to *R* and *Shuffle Repeats Variance* is set to **p**, then the actual shuffle repeats will be a random value (drawn uniformly) between **(1-p)R** and **(1+p)R**.
- *Minimum Shuffle Time*: If this value is set, then the base *Shuffle Repeats* must run for at least this many minutes in a given song. If the number of *Shuffle Repeats* is too short, then the number of repeats corresponding to the *Minimum Shuffle Time* will replace the configured *Shuffle Repeats* in the *Shuffle Repeats Variance* calculation.
- *Maximum Shuffle Time*: If this value is set, then the base *Shuffle Repeats* cannot run longer than this many minutes in a given song. If the number of *Shuffle Repeats* is too long, then the number of repeats corresponding to the *Maximum Shuffle Time* will replace the configured *Shuffle Repeats* in the *Shuffle Repeats Variance* calculation.

## Loop Finder Settings

See the [Loop Finder Settings page](loopfinder/loopfinder_settings.md).