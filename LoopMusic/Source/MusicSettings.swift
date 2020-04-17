import Foundation

/// Stores and loads app-level settings.
class MusicSettings {
    
    /// Singleton instance.
    static let settings: MusicSettings = MusicSettings()
    
    /// If true, music will start playing immediately when the app starts.
    private(set) var playOnInit: Bool
    
    init() {
        playOnInit = true
    }
}
