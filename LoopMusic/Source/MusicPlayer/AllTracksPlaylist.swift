import MediaPlayer

/// The default "All tracks" playlist that causes all tracks in the media library to be used.
class AllTracksPlaylist: MPMediaPlaylist {
    
    /// Cache of all tracks in the user's media library.
    var allTracks: [MPMediaItem]?
    
    override var name: String? {
        return "All tracks"
    }
    
    override var items: [MPMediaItem] {
        if allTracks == nil {
            if let queryResult: [MPMediaItem] = MPMediaQuery.songs().items {
                allTracks = queryResult
            }
        }
        if let allTracks = allTracks {
            return allTracks
        }
        return []
    }
}
