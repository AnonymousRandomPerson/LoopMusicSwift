import XCTest
import SQLite3
@testable import LoopMusic

let TRACK_URL: String = "testUrl"
let TRACK_NAME: String = "Test Name"

/// Tests the music data layer.
class MusicDataTests: XCTestCase {
    
    /// Singleton instance.
    let data: MusicData = MusicData.data
    
    override func setUp() {
        do {
            try data.openConnection()
        } catch {
            XCTFail(String(format: "Failed to open database connection. %@", error.localizedDescription))
        }
    }
    
    override func tearDown() {
        do {
            try data.executeSql(query: String(format: "DELETE FROM Tracks WHERE name = '%@'", TRACK_NAME), errorMessage: "")
        } catch {
            XCTFail(String(format: "Failed to clean up database. %@", error.localizedDescription))
        }
    }
    
    /// Tests that an existing track is loaded via URL.
    func testLoadTrackWithURL() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (url, name, loopStart, loopEnd, volumeMultiplier) VALUES ('%@', '%@', 2, 3, 0.5)", TRACK_URL, TRACK_NAME), errorMessage: "")
        
        /// Loaded track to assert on from the database.
        let loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        XCTAssertEqual(TRACK_URL, loadedTrack.url.absoluteString)
        XCTAssertEqual(TRACK_NAME, loadedTrack.name)
        XCTAssertEqual(2, loadedTrack.loopStart, accuracy: EPSILON)
        XCTAssertEqual(3, loadedTrack.loopEnd, accuracy: EPSILON)
        XCTAssertEqual(0.5, loadedTrack.volumeMultiplier, accuracy: EPSILON)
    }
    
    /// Tests that an existing track's name is updated when the media item's name changes.
    func testLoadTrackWithURLAndNameChange() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (url, name, loopStart, loopEnd, volumeMultiplier) VALUES ('%@', '%@', 2, 3, 0.5)", TRACK_URL, TRACK_NAME + "2"), errorMessage: "")
        
        /// Loaded track to assert on from the database.
        let loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        XCTAssertEqual(TRACK_URL, loadedTrack.url.absoluteString)
        XCTAssertEqual(TRACK_NAME, loadedTrack.name)
    }
    
    /// Tests that an existing track is loaded via fallback name.
    func testLoadTrackWithName() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (url, name) VALUES ('notTest', '%@')", TRACK_NAME), errorMessage: "")
        
        /// Loaded track to assert on from the database.
        let loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        XCTAssertEqual(TRACK_URL, loadedTrack.url.absoluteString)
        XCTAssertEqual(TRACK_NAME, loadedTrack.name)
        
        // Assert that the track's URL is updated.
        try data.executeSql(
            query: String(format: "SELECT COUNT(*) FROM Tracks WHERE url = '%@'", TRACK_URL),
            stepCallback: { (statement) in
                XCTAssertEqual(1, sqlite3_column_int(statement, 0))
            },
            noResultCallback: nil, errorMessage: "")
    }
    
    /// Tests that a new track is stored when attempting to load a track that doesn't exist in the database.
    func testLoadTrackNotFound() throws {
        /// Loaded track to assert on from the database.
        let loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        XCTAssertEqual(TRACK_URL, loadedTrack.url.absoluteString)
        XCTAssertEqual(TRACK_NAME, loadedTrack.name)
        
        try data.executeSql(
            query: "SELECT url, name FROM Tracks",
            stepCallback: { (statement) in
                XCTAssertEqual(TRACK_URL, String(cString: sqlite3_column_text(statement, 0)))
                XCTAssertEqual(TRACK_NAME, String(cString: sqlite3_column_text(statement, 1)))
            },
            noResultCallback: nil, errorMessage: "")
    }
    
    /// Tests that volume multiplier is updated correctly.
    func testUpdateVolumeMultiplier() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (id, url, name, loopStart, loopEnd, volumeMultiplier) VALUES (1, '%@', '%@', 2, 3, 0.5)", TRACK_URL, TRACK_NAME), errorMessage: "")
        
        /// Loaded track to assert on from the database.
        var loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        loadedTrack.volumeMultiplier = 0.7
        try data.updateVolumeMultiplier(track: loadedTrack)
        
        try data.executeSql(
            query: "SELECT volumeMultiplier FROM Tracks",
            stepCallback: { (statement) in
                XCTAssertEqual(0.7, sqlite3_column_double(statement, 0), accuracy: EPSILON)
            },
            noResultCallback: nil, errorMessage: "")
    }
    
    /// Tests that loop points are updated correctly.
    func testUpdateLoopPoints() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (id, url, name, loopStart, loopEnd, volumeMultiplier) VALUES (1, '%@', '%@', 2, 3, 0.5)", TRACK_URL, TRACK_NAME), errorMessage: "")
        
        /// Loaded track to assert on from the database.
        var loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        loadedTrack.loopStart = 1
        loadedTrack.loopEnd = 5
        try data.updateLoopPoints(track: loadedTrack)
        
        try data.executeSql(
            query: "SELECT loopStart, loopEnd FROM Tracks",
            stepCallback: { (statement) in
                XCTAssertEqual(1, sqlite3_column_double(statement, 0), accuracy: EPSILON)
                XCTAssertEqual(5, sqlite3_column_double(statement, 1), accuracy: EPSILON)
            },
            noResultCallback: nil, errorMessage: "")
    }
    
    /// Tests that escapeStringForDb() escapes single quotes.
    func testEscapeStringForDb() {
        XCTAssertEqual("Let''s Go", data.escapeStringForDb("Let's Go"))
    }
}
