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
    var currentPlaylist: MPMediaPlaylist = MediaPlayerUtils.ALL_TRACKS_PLAYLIST {
        didSet {
            NotificationCenter.default.post(name: .changePlaylist, object: nil)
        }
    }
    
    /// If true, music will start playing immediately when the app starts.
    var playOnInit: Bool = false
    /// Global volume multiplier for all tracks.
    var masterVolume: Double = 1
    /// Default relative volume for newly added tracks.
    var defaultRelativeVolume: Double = MusicTrack.DEFAULT_VOLUME_MULTIPLIER
    /// Volume in LUFS for automatic relative volume normalization.
    var volumeNormalizationLevel: Double?
    
    /// Setting for the time between shuffling tracks.
    var shuffleSetting: ShuffleSetting = ShuffleSetting.none
    /// Duration of fade-out just before shuffling tracks.
    var fadeDuration: Double?
    /// Number of tracks to store in history for recalling old tracks and for avoiding repeats when shuffling.
    var shuffleHistoryLength: Int?
    
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
    var loopTestOffset: Double = 3
    
    private init() {
    }
    
    /// Loads all settings from the settings file.
    func loadSettingsFile() throws {
        do {
            /// Deserialized settings file.
            let settingsFile: MusicSettingsCodable = try PropertyListDecoder().decode(MusicSettingsCodable.self, from: try Data(contentsOf: try FileUtils.getFileUrl(fileName: settingsFileName)))
            
            if let playlistName = settingsFile.currentPlaylist {
                currentPlaylist = MediaPlayerUtils.getPlaylist(playlistName: playlistName)
            } else {
                currentPlaylist = MediaPlayerUtils.ALL_TRACKS_PLAYLIST
            }
            playOnInit = settingsFile.playOnInit
            masterVolume = settingsFile.masterVolume
            defaultRelativeVolume = settingsFile.defaultRelativeVolume
            volumeNormalizationLevel = settingsFile.volumeNormalizationLevel
            shuffleSetting = ShuffleSetting(rawValue: settingsFile.shuffleSetting ?? "") ?? ShuffleSetting.none
            fadeDuration = settingsFile.fadeDuration
            shuffleHistoryLength = settingsFile.shuffleHistoryLength
            shuffleTime = settingsFile.shuffleTime
            shuffleTimeVariance = settingsFile.shuffleTimeVariance
            minShuffleRepeats = settingsFile.minShuffleRepeats
            maxShuffleRepeats = settingsFile.maxShuffleRepeats
            shuffleRepeats = settingsFile.shuffleRepeats
            shuffleRepeatsVariance = settingsFile.shuffleRepeatsVariance
            minShuffleTime = settingsFile.minShuffleTime
            maxShuffleTime = settingsFile.maxShuffleTime
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
            settingsFile.volumeNormalizationLevel = volumeNormalizationLevel
            settingsFile.shuffleSetting = shuffleSetting.rawValue
            settingsFile.shuffleTime = shuffleTime
            settingsFile.fadeDuration = fadeDuration
            settingsFile.shuffleHistoryLength = shuffleHistoryLength
            settingsFile.shuffleTimeVariance = shuffleTimeVariance
            settingsFile.minShuffleRepeats = minShuffleRepeats
            settingsFile.maxShuffleRepeats = maxShuffleRepeats
            settingsFile.shuffleRepeats = shuffleRepeats
            settingsFile.shuffleRepeatsVariance = shuffleRepeatsVariance
            settingsFile.minShuffleTime = minShuffleTime
            settingsFile.maxShuffleTime = maxShuffleTime
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
            trackShuffleTime = max(0, trackShuffleTime + Double.random(in: -shuffleVariance...shuffleVariance))
        }
        
        return trackShuffleTime
    }
    
    /// Calculates shuffle variance time based on the track and shuffle settings.
    /// - parameter repeatLength: The length of the track loop.
    /// - returns: Shuffle variance time based on settings.
    func calculateShuffleVariance(repeatLength: Double) -> Double? {
        if shuffleSetting == ShuffleSetting.time {
            if let shuffleTimeVariance: Double = shuffleTimeVariance {
                return shuffleTimeVariance * 60
            }
        } else if shuffleSetting == ShuffleSetting.repeats {
            if let shuffleRepeatsVariance: Double = shuffleRepeatsVariance {
                return shuffleRepeatsVariance * repeatLength
            }
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
        startTimeEstimateRadius = 1
        endTimeEstimateRadius = 1
        loopDurationEstimateRadius = 1
        startTimeEstimateDeviationPenalty = 0
        endTimeEstimateDeviationPenalty = 0
        loopDurationEstimateDeviationPenalty = 0
        minimumSearchDuration = 5
        durationSearchSeparation = 0.5
        durationSearchStartIgnore = 15
        durationSearchEndIgnore = 5
        fadeDetection = false
        endpointSearchDifferenceTolerance = 0.05
        fftLength = 1 << 15
        spectrogramOverlapPercentage = 50
        useMonoAudio = true
        frameRateReduction = 6
        frameRateReductionLimit = 10
        trackLengthLimit = Double(Int(1) << 22)
        durationValues = 12
        endpointPairs = 5
    }
    
    /// Sets settings in the loop finder.
    /// - parameter loopFinder: Loop finder instance to customize.
    /// - returns: Flag for whether any settings were changed.
    func customizeLoopFinder(loopFinder: LoopFinderAuto) -> Bool {
        // Record old values for comparison.
        let old_t1Radius = loopFinder.t1Radius
        let old_t2Radius = loopFinder.t2Radius
        let old_tauRadius = loopFinder.tauRadius
        let old_t1Penalty = loopFinder.t1Penalty
        let old_t2Penalty = loopFinder.t2Penalty
        let old_tauPenalty = loopFinder.tauPenalty
        let old_minLoopLength = loopFinder.minLoopLength
        let old_minTimeDiff = loopFinder.minTimeDiff
        let old_leftIgnore = loopFinder.leftIgnore
        let old_rightIgnore = loopFinder.rightIgnore
        let old_useFadeDetection = loopFinder.useFadeDetection
        let old_sampleDiffTol = loopFinder.sampleDiffTol
        let old_fftLength = loopFinder.fftLength
        let old_overlapPercent = loopFinder.overlapPercent
        let old_useMonoAudio = loopFinder.useMonoAudio
        let old_framerateReductionFactor = loopFinder.framerateReductionFactor
        let old_framerateReductionLimit = loopFinder.framerateReductionLimit
        let old_lengthLimit = loopFinder.lengthLimit
        let old_nBestDurations = loopFinder.nBestDurations
        let old_nBestPairs = loopFinder.nBestPairs

        // Assign the new values.
        loopFinder.t1Radius = Float(startTimeEstimateRadius)
        loopFinder.t2Radius = Float(endTimeEstimateRadius)
        loopFinder.tauRadius = Float(loopDurationEstimateRadius)
        loopFinder.t1Penalty = Float(startTimeEstimateDeviationPenalty)
        loopFinder.t2Penalty = Float(endTimeEstimateDeviationPenalty)
        loopFinder.tauPenalty = Float(loopDurationEstimateDeviationPenalty)
        loopFinder.minLoopLength = Float(minimumSearchDuration)
        loopFinder.minTimeDiff = Float(durationSearchSeparation)
        loopFinder.leftIgnore = Float(durationSearchStartIgnore)
        loopFinder.rightIgnore = Float(durationSearchEndIgnore)
        loopFinder.useFadeDetection = fadeDetection
        loopFinder.sampleDiffTol = Float(endpointSearchDifferenceTolerance)
        loopFinder.fftLength = UInt32(fftLength)
        loopFinder.overlapPercent = Float(spectrogramOverlapPercentage)
        loopFinder.useMonoAudio = useMonoAudio
        loopFinder.framerateReductionFactor = Int32(frameRateReduction)
        loopFinder.setFramerateReductionLimitFloat(Float(frameRateReductionLimit))
        loopFinder.setLengthLimitFloat(Float(trackLengthLimit))
        loopFinder.nBestDurations = durationValues
        loopFinder.nBestPairs = endpointPairs

        // Check for differences.
        if loopFinder.t1Radius != old_t1Radius { return true }
        if loopFinder.t2Radius != old_t2Radius { return true }
        if loopFinder.tauRadius != old_tauRadius { return true }
        if loopFinder.t1Penalty != old_t1Penalty { return true }
        if loopFinder.t2Penalty != old_t2Penalty { return true }
        if loopFinder.tauPenalty != old_tauPenalty { return true }
        if loopFinder.minLoopLength != old_minLoopLength { return true }
        if loopFinder.minTimeDiff != old_minTimeDiff { return true }
        if loopFinder.leftIgnore != old_leftIgnore { return true }
        if loopFinder.rightIgnore != old_rightIgnore { return true }
        if loopFinder.useFadeDetection != old_useFadeDetection { return true }
        if loopFinder.sampleDiffTol != old_sampleDiffTol { return true }
        if loopFinder.fftLength != old_fftLength { return true }
        if loopFinder.overlapPercent != old_overlapPercent { return true }
        if loopFinder.useMonoAudio != old_useMonoAudio { return true }
        if loopFinder.framerateReductionFactor != old_framerateReductionFactor { return true }
        if loopFinder.framerateReductionLimit != old_framerateReductionLimit { return true }
        if loopFinder.lengthLimit != old_lengthLimit { return true }
        if loopFinder.nBestDurations != old_nBestDurations { return true }
        if loopFinder.nBestPairs != old_nBestPairs { return true }

        // No change.
        return false
    }
}
