import MediaPlayer

/// Stores and loads app-level settings.
class MusicSettings {
    
    /// File to write settings to.
    static let SETTINGS_FILE: String = "Settings.plist"
    
    /// Singleton instance.
    static let settings: MusicSettings = MusicSettings()
    
    /// File to write settings to.
    var settingsFileName: String = SETTINGS_FILE
    
    /// Playlist being used to choose tracks.
    var currentPlaylist: MPMediaPlaylist = MediaPlayerUtils.ALL_TRACKS_PLAYLIST
    
    /// If true, music will start playing immediately when the app starts.
    var playOnInit: Bool = false
    /// Global volume multiplier for all tracks.
    var masterVolume: Double = 1
    /// Default relative volume for newly added tracks.
    var defaultRelativeVolume: Double = MusicTrack.DEFAULT_VOLUME_MULTIPLIER
    
    /// Setting for the time between shuffling tracks.
    var shuffleSetting: ShuffleSetting = ShuffleSetting.none
    /// Duration of fade-out just before shuffling tracks.
    var fadeDuration: Double?
    
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
    
    /// True if the loop finder will use the current loop times as an initial estimate for finding better times.
    var initialEstimate: Bool = false
    /// How far the loop finder will deviate from the start time estimate (seconds).
    var startTimeEstimateRadius: Double?
    /// How far the loop finder will deviate from the end time estimate (seconds).
    var endTimeEstimateRadius: Double?
    /// How far the loop finder will deviate from the loop duration estimate (seconds).
    var loopDurationEstimateRadius: Double?
    /// How much the loop finder penalizes start time estimate deviation.
    var startTimeEstimateDeviationPenalty: Double = 0
    /// How much the loop finder penalizes end time estimate deviation.
    var endTimeEstimateDeviationPenalty: Double = 0
    /// How much the loop finder penalizes loop duration estimate deviation.
    var loopDurationEstimateDeviationPenalty: Double = 0
    var minimumSearchDuration: Double?
    var durationSearchSeparation: Double?
    var durationSearchStartIgnore: Double?
    var durationSearchEndIgnore: Double?
    var fadeDetection: Bool = false
    var endpointSearchDifferenceTolerance: Double?
    var fftLength: Double?
    var spectrogramOverlapPercentage: Double?
    /// Controls whether to use mono audio data rather than stereo data for certain parts of analysis. Usually gives about a 2x speedup, but may reduce accuracy.
    var useMonoAudio: Bool = false
    /// Controls how to reduce the framerate of the audio data before loop-finding. Usually gives a speedup factor equal to the reduction value, but may be less accurate. Values of 7+ may cause algorithm instability.
    var frameRateReduction: Double?
    /// Limit of frame rate reduction when the loop finder downsamples.
    var frameRateReductionLimit: Double?
    /// Proportional to the frame rate reduction limit.
    var trackLengthLimit: Double?
    /// Number of duration values outputted by the loop finder.
    var durationValues: Double?
    /// Number of endpoint pairs outputted by the loop finder.
    var endpointPairs: Double?
    /// If enabled, the loop will be tested automatically when loop points are changed.
    var testLoopOnChange: Bool = true
    /// The amount of time (seconds) before the loop end that audio playback will be set to when testing the loop.
    var loopTestOffset: Double?
    
    private init() {
    }
    
    /// Loads all settings from the settings file.
    func loadSettingsFile() throws {
        do {
            /// Deserialized settings file.
            let settingsFile: MusicSettingsCodable = try PropertyListDecoder().decode(MusicSettingsCodable.self, from: try Data(contentsOf: try FileUtils.getFileUrl(fileName: settingsFileName)))
            
            if let playlistName = settingsFile.currentPlaylist {
                currentPlaylist = MediaPlayerUtils.getPlaylist(playlistName: playlistName)
            }
            playOnInit = settingsFile.playOnInit
            masterVolume = settingsFile.masterVolume
            defaultRelativeVolume = settingsFile.defaultRelativeVolume
            shuffleSetting = ShuffleSetting(rawValue: settingsFile.shuffleSetting ?? "") ?? ShuffleSetting.none
            fadeDuration = settingsFile.fadeDuration
            shuffleTime = settingsFile.shuffleTime
            shuffleTimeVariance = settingsFile.shuffleTimeVariance
            minShuffleRepeats = settingsFile.minShuffleRepeats
            maxShuffleRepeats = settingsFile.maxShuffleRepeats
            shuffleRepeats = settingsFile.shuffleRepeats
            shuffleRepeatsVariance = settingsFile.shuffleRepeatsVariance
            minShuffleTime = settingsFile.minShuffleTime
            maxShuffleTime = settingsFile.maxShuffleTime
            initialEstimate = settingsFile.initialEstimate
            startTimeEstimateRadius = settingsFile.startTimeEstimateRadius
            endTimeEstimateRadius = settingsFile.endTimeEstimateRadius
            loopDurationEstimateRadius = settingsFile.loopDurationEstimateRadius
            startTimeEstimateDeviationPenalty = settingsFile.startTimeEstimateDeviationPenalty
            endTimeEstimateDeviationPenalty = settingsFile.endTimeEstimateDeviationPenalty
            loopDurationEstimateDeviationPenalty = settingsFile.loopDurationEstimateDeviationPenalty
            minimumSearchDuration = settingsFile.minimumSearchDuration
            durationSearchSeparation = settingsFile.durationSearchSeparation
            durationSearchStartIgnore = settingsFile.durationSearchStartIgnore
            durationSearchEndIgnore = settingsFile.durationSearchEndIgnore
            fadeDetection = settingsFile.fadeDetection
            endpointSearchDifferenceTolerance = settingsFile.endpointSearchDifferenceTolerance
            fftLength = settingsFile.fftLength
            spectrogramOverlapPercentage = settingsFile.spectrogramOverlapPercentage
            useMonoAudio = settingsFile.useMonoAudio
            frameRateReduction = settingsFile.frameRateReduction
            frameRateReductionLimit = settingsFile.frameRateReductionLimit
            trackLengthLimit = settingsFile.trackLengthLimit
            durationValues = settingsFile.durationValues
            endpointPairs = settingsFile.endpointPairs
            testLoopOnChange = settingsFile.testLoopOnChange
            loopTestOffset = settingsFile.loopTestOffset
        } catch {
            print("Settings file not found. Creating a new one.", error)
            resetLoopFinderSettings()
            try saveSettingsFile()
        }
    }
    
    /// Saves all settings to the settings file.
    func saveSettingsFile() throws {
        let encoder: PropertyListEncoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            var settingsFile: MusicSettingsCodable = MusicSettingsCodable()
            if currentPlaylist !== MediaPlayerUtils.ALL_TRACKS_PLAYLIST {
                settingsFile.currentPlaylist = currentPlaylist.name
            }
            settingsFile.playOnInit = playOnInit
            settingsFile.masterVolume = masterVolume
            settingsFile.defaultRelativeVolume = defaultRelativeVolume
            settingsFile.shuffleSetting = shuffleSetting.rawValue
            settingsFile.shuffleTime = shuffleTime
            settingsFile.fadeDuration = fadeDuration
            settingsFile.shuffleTimeVariance = shuffleTimeVariance
            settingsFile.minShuffleRepeats = minShuffleRepeats
            settingsFile.maxShuffleRepeats = maxShuffleRepeats
            settingsFile.shuffleRepeats = shuffleRepeats
            settingsFile.shuffleRepeatsVariance = shuffleRepeatsVariance
            settingsFile.minShuffleTime = minShuffleTime
            settingsFile.maxShuffleTime = maxShuffleTime
            settingsFile.initialEstimate = initialEstimate
            settingsFile.startTimeEstimateRadius = startTimeEstimateRadius
            settingsFile.endTimeEstimateRadius = endTimeEstimateRadius
            settingsFile.loopDurationEstimateRadius = loopDurationEstimateRadius
            settingsFile.startTimeEstimateDeviationPenalty = startTimeEstimateDeviationPenalty
            settingsFile.endTimeEstimateDeviationPenalty = endTimeEstimateDeviationPenalty
            settingsFile.loopDurationEstimateDeviationPenalty = loopDurationEstimateDeviationPenalty
            settingsFile.minimumSearchDuration = minimumSearchDuration
            settingsFile.durationSearchSeparation = durationSearchSeparation
            settingsFile.durationSearchStartIgnore = durationSearchStartIgnore
            settingsFile.durationSearchEndIgnore = durationSearchEndIgnore
            settingsFile.fadeDetection = fadeDetection
            settingsFile.endpointSearchDifferenceTolerance = endpointSearchDifferenceTolerance
            settingsFile.fftLength = fftLength
            settingsFile.spectrogramOverlapPercentage = spectrogramOverlapPercentage
            settingsFile.useMonoAudio = useMonoAudio
            settingsFile.frameRateReduction = frameRateReduction
            settingsFile.frameRateReductionLimit = frameRateReductionLimit
            settingsFile.trackLengthLimit = trackLengthLimit
            settingsFile.durationValues = durationValues
            settingsFile.endpointPairs = endpointPairs
            settingsFile.testLoopOnChange = testLoopOnChange
            settingsFile.loopTestOffset = loopTestOffset
            
            try encoder.encode(settingsFile).write(to: FileUtils.getFileUrl(fileName: settingsFileName))
        } catch {
            throw MessageError("Failed to save settings.", error)
        }
    }
    
    /// Calculates shuffle time based on the track and shuffle settings.
    /// - parameter track: Track used to calculate repeat times.
    /// - returns: The shuffle time to use for the track.
    func calculateShuffleTime(track: MusicTrack) -> Double? {
        if shuffleSetting == ShuffleSetting.none {
            return nil
        }
        
        /// Length (seconds) of a track repeat.
        let repeatLength: Double = track.loopEnd - track.loopStart
        /// Time to wait before shuffling the track.
        var trackShuffleTime: Double = 0
        if shuffleSetting == ShuffleSetting.time {
            if let shuffleTime: Double = shuffleTime {
                trackShuffleTime = shuffleTime * 60
            } else {
                return nil
            }
        } else {
            if let shuffleRepeats: Double = shuffleRepeats {
                trackShuffleTime = shuffleRepeats * repeatLength + track.loopStart
            } else {
                return nil
            }
        }
        
        if let minShuffleTime: Double = calculateMinShuffleTime(repeatLength: repeatLength) {
            trackShuffleTime = max(trackShuffleTime, minShuffleTime)
        }
        
        if let maxShuffleTime: Double = calculateMaxShuffleTime(repeatLength: repeatLength) {
            trackShuffleTime = min(trackShuffleTime, maxShuffleTime)
        }
        
        if let shuffleVariance: Double = calculateShuffleVariance(repeatLength: repeatLength) {
            trackShuffleTime += Double.random(in: -shuffleVariance...shuffleVariance)
        }
        
        return trackShuffleTime
    }
    
    /// Calculates shuffle variance time based on the track and shuffle settings.
    /// - parameter repeatLength: The length of the track loop.
    /// - returns: Shuffle variance time based on settings.
    func calculateShuffleVariance(repeatLength: Double) -> Double? {
        if let shuffleTimeVariance: Double = shuffleTimeVariance {
            return shuffleTimeVariance * 60
        } else if let shuffleRepeatsVariance: Double = shuffleRepeatsVariance {
            return shuffleRepeatsVariance * repeatLength
        }
        return nil
    }
    
    /// Calculates minimum shuffle time based on the track and shuffle settings.
    /// - parameter repeatLength: The length of the track loop.
    /// - returns: Minimum shuffle time based on settings.
    func calculateMinShuffleTime(repeatLength: Double) -> Double? {
        if shuffleSetting == ShuffleSetting.time {
            if let minShuffleRepeats: Double = minShuffleRepeats {
                return minShuffleRepeats * repeatLength
            }
        } else if shuffleSetting == ShuffleSetting.repeats {
            if let minShuffleTime: Double = minShuffleTime {
                return minShuffleTime * 60
            }
        }
        return nil;
    }
    
    /// Calculates maximum shuffle time based on the track and shuffle settings.
    /// - parameter repeatLength: The length of the track loop.
    /// - returns: Maximum shuffle time based on settings.
    func calculateMaxShuffleTime(repeatLength: Double) -> Double? {
        if shuffleSetting == ShuffleSetting.time {
            if let maxShuffleRepeats: Double = maxShuffleRepeats {
                return maxShuffleRepeats * repeatLength
            }
        } else if shuffleSetting == ShuffleSetting.repeats {
            if let maxShuffleTime: Double = maxShuffleTime {
                return maxShuffleTime * 60
            }
        }
        return nil;
    }
    
    /// Resets all loop finder settings to their default values.
    func resetLoopFinderSettings() {
        startTimeEstimateRadius = 0
        endTimeEstimateRadius = 0
        loopDurationEstimateRadius = 0
        startTimeEstimateDeviationPenalty = 0
        endTimeEstimateDeviationPenalty = 0
        loopDurationEstimateDeviationPenalty = 0
        minimumSearchDuration = 0
        durationSearchSeparation = 0
        durationSearchStartIgnore = 0
        durationSearchEndIgnore = 0
        fadeDetection = false
        endpointSearchDifferenceTolerance = 0
        fftLength = 0
        spectrogramOverlapPercentage = 0
        useMonoAudio = false
        frameRateReduction = 0
        frameRateReductionLimit = 0
        trackLengthLimit = 0
        durationValues = 0
        endpointPairs = 0
    }
}
