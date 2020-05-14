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
            shuffleTime = settingsFile.shuffleTime
            shuffleTimeVariance = settingsFile.shuffleTimeVariance
            minShuffleRepeats = settingsFile.minShuffleRepeats
            maxShuffleRepeats = settingsFile.maxShuffleRepeats
            shuffleRepeats = settingsFile.shuffleRepeats
            shuffleRepeatsVariance = settingsFile.shuffleRepeatsVariance
            minShuffleTime = settingsFile.minShuffleTime
            maxShuffleTime = settingsFile.maxShuffleTime
        } catch {
            print("Settings file not found. Creating a new one.", error)
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
            settingsFile.shuffleTimeVariance = shuffleTimeVariance
            settingsFile.minShuffleRepeats = minShuffleRepeats
            settingsFile.maxShuffleRepeats = maxShuffleRepeats
            settingsFile.shuffleRepeats = shuffleRepeats
            settingsFile.shuffleRepeatsVariance = shuffleRepeatsVariance
            settingsFile.minShuffleTime = minShuffleTime
            settingsFile.maxShuffleTime = maxShuffleTime
            
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
        /// Minimum shuffle time based on settings.
        var minShuffle: Double?
        if let minShuffleTime: Double = minShuffleTime {
            minShuffle = minShuffleTime * 60
        }
        if let minShuffleRepeats: Double = minShuffleRepeats {
            let repeatsTime: Double = minShuffleRepeats * repeatLength
            if let currentMinShuffle: Double = minShuffle {
                minShuffle = max(currentMinShuffle, repeatsTime)
            } else {
                minShuffle = repeatsTime
            }
        }
        return minShuffle
    }
    
    /// Calculates maximum shuffle time based on the track and shuffle settings.
    /// - parameter repeatLength: The length of the track loop.
    /// - returns: Maximum shuffle time based on settings.
    func calculateMaxShuffleTime(repeatLength: Double) -> Double? {
        /// Maximum shuffle time based on settings.
        var maxShuffle: Double?
        if let maxShuffleTime: Double = maxShuffleTime {
            maxShuffle = maxShuffleTime * 60
        }
        if let maxShuffleRepeats: Double = maxShuffleRepeats {
            let repeatsTime: Double = maxShuffleRepeats * repeatLength
            if let currentMaxShuffle: Double = maxShuffle {
                maxShuffle = min(currentMaxShuffle, repeatsTime)
            } else {
                maxShuffle = repeatsTime
            }
        }
        return maxShuffle
    }
}
