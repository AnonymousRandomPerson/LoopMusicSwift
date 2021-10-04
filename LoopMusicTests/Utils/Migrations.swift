import SQLite3
import XCTest
import MediaPlayer
@testable import LoopMusic

/// Used to run migrations on the database, often running some metadata modification on all the tracks in the database.
class Migrations: XCTestCase {
    
    /// Music data instance.
    let data: MusicData = MusicData.data
    /// Music player instance.
    let player: LoopMusic.MusicPlayer = MusicPlayer.player
    
    override func setUp() {
        do {
            try data.openConnection()
        } catch {
            XCTFail(String(format: "Failed to open database connection. %@", error.localizedDescription))
        }
    }
    
    override func tearDown() {
        do {
            try data.closeConnection()
        } catch {
            XCTFail(String(format: "Failed to close database connection. %@", error.localizedDescription))
        }
    }

    /// Loop through the All Tracks playlist and return the MPMediaItems that have a corresponding entry in the Tracks database.
    func getAllTracksInDatabase() throws -> [MPMediaItem] {
        var tracksInDb: [MPMediaItem] = []
        var titles: Set<String> = []
        for mediaItem in MediaPlayerUtils.ALL_TRACKS_PLAYLIST.items {
            if let trackURL: URL = mediaItem.assetURL, let trackName: String = mediaItem.title {
                try data.executeSql(
                    query: String(format: "SELECT COUNT(*) FROM Tracks WHERE url = '%@'", data.escapeStringForDb(trackURL.absoluteString)),
                    stepCallback: {(statement: OpaquePointer?) -> Void in
                        let count = sqlite3_column_int64(statement, 0)
                        if count > 0 {
                            if count > 1 {
                                print("Warning: multiple matches for track \(trackURL)")
                            }
                            if titles.contains(trackName) {
                                print("Warning: duplicate title: \(trackName)")
                            } else {
                                tracksInDb.append(mediaItem)
                                titles.insert(trackName)
                            }
                        } else {
                            try self.data.executeSql(
                                query: String(format: "SELECT COUNT(*) FROM Tracks WHERE name = '%@'", self.data.escapeStringForDb(trackName)),
                                stepCallback: {(statement: OpaquePointer?) -> Void in
                                    let count = sqlite3_column_int64(statement, 0)
                                    if count > 0 {
                                        if count > 1 {
                                            print("Warning: multiple matches for track \(trackName)")
                                        }
                                        if titles.contains(trackName) {
                                            print("Warning: duplicate title: \(trackName)")
                                        } else {
                                            tracksInDb.append(mediaItem)
                                            titles.insert(trackName)
                                        }
                                    }
                                },
                                noResultCallback: nil,
                                errorMessage: String(format: "Failed to load track: %@.", trackName)
                            )
                        }
                    },
                    noResultCallback: nil,
                    errorMessage: String(format: "Failed to load track: %@.", trackName)
                )
            }
        }
        return tracksInDb
    }
    
    /// Prints the number of samples for each track in the database.
    func testPrintNumSamples() throws {
        let tracksInDb = try getAllTracksInDatabase()
        
        for track in tracksInDb {
            try player.loadTrack(mediaItem: track, updateHistory: false)
            print("\(track.title!): \(player.numSamples)")
        }
    }
}
