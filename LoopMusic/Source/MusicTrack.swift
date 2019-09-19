import Foundation;

/// Metadata for a music track, relevant for playback and looping.
struct MusicTrack {
    
    /// The URL of the audio file.
    let url: URL
    
    /// The frame number at the start of the track's loop.
    let loopStart: Int64
    
    /// The frame number at the end of the track's loop.
    let loopEnd: Int64
}
