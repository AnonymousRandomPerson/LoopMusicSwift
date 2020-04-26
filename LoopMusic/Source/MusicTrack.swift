import Foundation

/// Metadata for a music track, relevant for playback and looping.
struct MusicTrack {
    
    /// The default volume multiplier for new tracks.
    static let DEFAULT_VOLUME_MULTIPLIER: Double = 0.3
    /// Indicates the absence of a music track.
    static let BLANK_MUSIC_TRACK: MusicTrack = MusicTrack(url: URL(fileURLWithPath: ""), name: "", loopStart: 0, loopEnd: 0, volumeMultiplier: DEFAULT_VOLUME_MULTIPLIER)
    
    /// URL of the audio file.
    let url: URL
    
    /// Display name of the track.
    let name: String
    
    /// Time (seconds) at the start of the track's loop.
    let loopStart: Double
    
    /// Time (seconds) at the end of the track's loop.
    let loopEnd: Double
    
    /// Multiplier used to alter the volume of the track.
    let volumeMultiplier: Double
}
