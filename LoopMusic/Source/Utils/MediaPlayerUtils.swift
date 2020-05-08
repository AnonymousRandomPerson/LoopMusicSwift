import MediaPlayer

/// Utility function for media queries.
class MediaPlayerUtils {
    
    /// The default "All tracks" playlist that causes all tracks in the media library to be used.
    static let ALL_TRACKS_PLAYLIST: AllTracksPlaylist = AllTracksPlaylist(items: [])
    
    /// Gets a list of tracks in the current playlist, or all tracks if no playlist is selected.
    /// - returns: List of tracks in the current playlist.
    static func getTracksInPlaylist() -> [MPMediaItem] {
        // Apple Music tracks have DRM protection and inaccessible asset URLs. This app cannot support them.
        return MusicSettings.settings.currentPlaylist.items.filter { $0.assetURL != nil }
    }
    
    /// Gets all playlists in the media library, plus the "All tracks" default playlist.
    /// - returns: List of playlists in the media library plus "All tracks".
    static func getPlaylists() -> [MPMediaPlaylist] {
        var playlists: [MPMediaPlaylist] = [MediaPlayerUtils.ALL_TRACKS_PLAYLIST]
        if let queryPlaylists: [MPMediaPlaylist] = MPMediaQuery.playlists().collections as? [MPMediaPlaylist] {
            playlists.append(contentsOf: queryPlaylists)
        }
        return playlists
    }
    
    /// Gets a playlist from the media library by name.
    /// - parameter playlistName: Name of the playlist to get.
    /// - returns: Playlist with the specified name, or "All tracks" if the playlist can't be found.
    static func getPlaylist(playlistName: String) -> MPMediaPlaylist {
        let query: MPMediaQuery = MPMediaQuery.playlists()
        query.filterPredicates = NSSet(object: MPMediaPropertyPredicate(value: playlistName, forProperty: MPMediaItemPropertyTitle)) as? Set<MPMediaPredicate>
        if let playlists: [MPMediaPlaylist] = query.collections as? [MPMediaPlaylist] {
            for playlist in playlists {
                return playlist
            }
        }
        return ALL_TRACKS_PLAYLIST
    }
}
