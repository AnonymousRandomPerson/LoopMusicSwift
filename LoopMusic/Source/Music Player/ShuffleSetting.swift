/// Possible settings for shuffling tracks.
enum ShuffleSetting {
    /// No automatic shuffle.
    case none
    /// Shuffle after an amount of time.
    case time
    /// Shuffle after the track repeats a number of times.
    case repeats
}
