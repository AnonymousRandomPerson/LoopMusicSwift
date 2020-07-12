/// Metadata for a music track, relevant for playback and looping.
struct MusicTrack {
    
    /// The default volume multiplier for new tracks.
    static let DEFAULT_VOLUME_MULTIPLIER: Double = 0.3
    /// Null object pattern indicating the absence of a music track.
    static let BLANK_MUSIC_TRACK: MusicTrack = MusicTrack(id: -1, url: URL(fileURLWithPath: ""), name: "", loopStart: 0, loopEnd: 0, volumeMultiplier: DEFAULT_VOLUME_MULTIPLIER)
    
    /// Database ID of the track.
    let id: Int64
    
    /// URL of the audio file.
    let url: URL
    
    /// Display name of the track.
    let name: String
    
    /// Time (seconds) at the start of the track's loop.
    var loopStart: Double
    
    /// Time (seconds) at the end of the track's loop.
    var loopEnd: Double
    
    /// Multiplier used to alter the volume of the track.
    var volumeMultiplier: Double
}
