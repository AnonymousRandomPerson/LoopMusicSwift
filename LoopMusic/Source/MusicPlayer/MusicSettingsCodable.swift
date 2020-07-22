/// Serializable version of MusicSettings.
struct MusicSettingsCodable: Codable {
    
    /// Playlist being used to choose tracks.
    var currentPlaylist: String?
    
    /// If true, music will start playing immediately when the app starts.
    var playOnInit: Bool = false
    
    /// Setting for the time between shuffling tracks.
    var shuffleSetting: String?
    /// Duration of fade-out just before shuffling tracks.
    var fadeDuration: Double?
    /// Number of tracks to store in history for recalling old tracks and for avoiding repeats when shuffling.
    var shuffleHistoryLength: Int?
    /// Global volume multiplier for all tracks.
    var masterVolume: Double = 1
    /// Default relative volume for newly added tracks.
    var defaultRelativeVolume: Double = MusicTrack.DEFAULT_VOLUME_MULTIPLIER
    /// Volume in decibels for automatic relative volume normalization.
    var volumeNormalizationLevel: Double?
    
    /// For time shuffle, the base amount of time (minutes) to shuffle tracks at.
    var shuffleTime: Double?
    /// For time shuffle, a random variance (minutes) to add or subtract to the base shuffle time.
    var shuffleTimeVariance: Double?
    /// For time shuffle, the minimum number of repeats for a track, regardless of the shuffle time.
    var minShuffleRepeats: Double?
    /// For time shuffle, the maximum number of repeats for a track, regardless of the shuffle time.
    var maxShuffleRepeats: Double?
    
    /// For repeats shuffle, the base amount of repeats to shuffle tracks at.
    var shuffleRepeats: Double?
    /// For repeats shuffle, a random variance to add or subtract to the base shuffle repeats.
    var shuffleRepeatsVariance: Double?
    /// For repeats shuffle, the minimum amount of time (minutes) for a track, regardless of the shuffle repeats.
    var minShuffleTime: Double?
    /// For repeats shuffle, the maximum amount of time (minutes) for a track, regardless of the shuffle repeats.
    var maxShuffleTime: Double?
    
    /// How far the loop finder will deviate from the start time estimate (seconds).
    var startTimeEstimateRadius: Double = 0
    /// How far the loop finder will deviate from the end time estimate (seconds).
    var endTimeEstimateRadius: Double = 0
    /// How far the loop finder will deviate from the loop duration estimate (seconds).
    var loopDurationEstimateRadius: Double = 0
    /// How much the loop finder penalizes start time estimate deviation.
    var startTimeEstimateDeviationPenalty: Double = 0
    /// How much the loop finder penalizes end time estimate deviation.
    var endTimeEstimateDeviationPenalty: Double = 0
    /// How much the loop finder penalizes loop duration estimate deviation.
    var loopDurationEstimateDeviationPenalty: Double = 0
    var minimumSearchDuration: Double = 0
    var durationSearchSeparation: Double = 0
    var durationSearchStartIgnore: Double = 0
    var durationSearchEndIgnore: Double = 0
    var fadeDetection: Bool = false
    var endpointSearchDifferenceTolerance: Double = 0
    var fftLength: Int = 0
    var spectrogramOverlapPercentage: Double = 0
    /// Controls whether to use mono audio data rather than stereo data for certain parts of analysis. Usually gives about a 2x speedup, but may reduce accuracy.
    var useMonoAudio: Bool = false
    /// Controls how to reduce the framerate of the audio data before loop-finding. Usually gives a speedup factor equal to the reduction value, but may be less accurate. Values of 7+ may cause algorithm instability.
    var frameRateReduction: Int = 0
    /// Limit of frame rate reduction when the loop finder downsamples.
    var frameRateReductionLimit: Double = 0
    /// Proportional to the frame rate reduction limit.
    var trackLengthLimit: Double = 0
    /// Number of duration values outputted by the loop finder.
    var durationValues: Int = 0
    /// Number of endpoint pairs outputted by the loop finder.
    var endpointPairs: Int = 0
    /// If enabled, the loop will be tested automatically when loop points are changed.
    var testLoopOnChange: Bool = true
    /// The amount of time (seconds) before the loop end that audio playback will be set to when testing the loop.
    var loopTestOffset: Double = 0
}
