import MediaPlayer

class MediaPlayerUtils {
    
    /// Gets a list of tracks in the current playlist, or all tracks if no playlist is selected.
    /// - returns: List of tracks in the current playlist.
    static func getTracksInPlaylist() -> [MPMediaItem] {
        let query: MPMediaQuery = MPMediaQuery.playlists()
        if let currentPlaylist: String = MusicSettings.settings.currentPlaylist {
            query.filterPredicates = NSSet(object: MPMediaPropertyPredicate(value: currentPlaylist, forProperty: MPMediaItemPropertyTitle)) as? Set<MPMediaPredicate>
            var playlistTracks: [MPMediaItem]?
            if let playlists: [MPMediaItemCollection] = query.collections {
                for playlist in playlists {
                    playlistTracks = playlist.items
                    break
                }
            }
            
            if let playlistTracks: [MPMediaItem] = playlistTracks {
                return playlistTracks
            }
        }
        
        if let allTracks: [MPMediaItem] = MPMediaQuery.songs().items {
            return allTracks
        } else {
            return []
        }
    }
}
