import MediaPlayer

/// Stores and loads app-level settings.
class MusicSettings {
    
    /// Singleton instance.
    static let settings: MusicSettings = MusicSettings()
    
    /// Playlist being used to choose tracks.
    var currentPlaylist: MPMediaPlaylist = MediaPlayerUtils.ALL_TRACKS_PLAYLIST
    
    /// If true, music will start playing immediately when the app starts.
    var playOnInit: Bool = false
    
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
    
    /// Private constructor for singleton.
    private init() {
    }
    
    /// Loads all settings from the settings file.
    func loadSettingsFile() {
        if 
        let playlistName: String = "LoopMusic"
        currentPlaylist = MediaPlayerUtils.getPlaylist(playlistName: playlistName)
        playOnInit = false
        shuffleSetting = ShuffleSetting.time
        shuffleTime = 5
        shuffleTimeVariance = 1
        minShuffleRepeats = 1
        maxShuffleRepeats = 5
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
