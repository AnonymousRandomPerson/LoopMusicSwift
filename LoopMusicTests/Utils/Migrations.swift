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
    /// Music settings instance.
    let settings: MusicSettings = MusicSettings.settings
    
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

    /// Normalizes all tracks to the recommended loudness of -23 LUFS. To run, add "test" in front of this function's name and run it.
    /// WARNING: This will modify the volumeMultiplier of all tracks in the database.
    func normalizeTrackVolumes() throws {
        let NORMALIZATION_LEVEL: Double = -23
        let tracksInDb = try getAllTracksInDatabase()

        for (i, track) in tracksInDb.enumerated() {
            try player.loadTrack(mediaItem: track, updateHistory: false)

            // Compute the track's intrinsic average volume.
            var audioData = player.audioData
            // Only use up to the loop end for the loudness calculation (loopEnd is exclusive). For reasons I don't understand, it appears that sometimes loopEnd and audioData.numSamples can get out of sync by the number of priming frames...so ensure that loopEnd <= audioData.numSamples.
            let numSamples = min(MusicPlayer.player.loopEnd, Int(audioData.numSamples))
            // Never reduce the framerate by more than a factor of 4. For a standard 44.1 kHz signal, a factor of 4 reduction gives an effective framerate of 11.025 kHz, with a corresponding Nyquist frequency of 5.5125 kHz. Since the human ear is most sensitive to frequencies between 2 kHz and 5 kHz, reducing any further would seriously degrade the quality of the loudness calculation, which is designed to weight frequencies in a way that reflects human perception.
            let framerateReductionLimit: Int = min(4, Int(round(settings.frameRateReductionLimit)))
            let lengthLimit: Int = Int(settings.trackLengthLimit)
            var intrinsicLoudness: Double = 0
            // Wait for the track to be loaded fully. We need to do this here because we're trying to calculate the loudness right after loading the track, at programmatic speed. Normally by the time the user can open the UI to trigger this function call, the track will already have been loaded fully, and we wouldn't want to make the user wait like that anyway.
            while (!player.trackFullyLoaded) {
                usleep(10000)
            }
            if (calcIntegratedLoudnessFromBufferFormat(&audioData, numSamples, framerateReductionLimit, lengthLimit, &intrinsicLoudness) < 0) {
                print("WARNING: Failed to calculate integrated loudness for track: \(track.title!)")
                continue
            }

            // Try to shift the average volume to the desired level by setting the relative volume multiplier.
            // The shift must be nonpositive since we can't raise the volume higher than the intrinsic volume.
            let dbShift = min(0, NORMALIZATION_LEVEL - intrinsicLoudness)
            let relativeVolume = pow(10, dbShift/20)
            print("[\(i+1)/\(tracksInDb.count)] \(track.title!): \(player.volumeMultiplier) -> \(relativeVolume)")
            player.volumeMultiplier = relativeVolume
            try player.saveTrackSettings()
        }
    }
}
