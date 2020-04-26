import XCTest
import MediaPlayer
import SQLite3
@testable import LoopMusic

let TRACK_URL: String = "testUrl"
let TRACK_NAME: String = "Test Name"

/// Tests the music data layer.
class MusicDataTests: XCTestCase {
    
    let data: MusicData = MusicData.data
    
    /// Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        do {
            try data.openConnection()
        } catch let error as NSError {
            XCTFail(String(format: "Failed to open database connection. %@", error.code.description))
        }
    }
    
    /// Put teardown code here. This method is called after the invocation of each test method in the class.
    override func tearDown() {
        do {
            try data.executeSql(query: String(format: "DELETE FROM Tracks WHERE name = '%@'", TRACK_NAME), errorMessage: "")
        } catch let error as NSError {
            XCTFail(String(format: "Failed to clean up database. %@", error.code.description))
        }
    }
    
    /// Tests that an existing track is loaded via URL.
    func testLoadTrackWithURL() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (url, name, loopStart, loopEnd, volumeMultiplier) VALUES ('%@', '%@', 2, 3, 0.5)", TRACK_URL, TRACK_NAME), errorMessage: "")
        
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
        
        let loadedTrack: LoopMusic.MusicTrack = try data.loadTrack(mediaItem: TestMPMediaItem())
        XCTAssertEqual(TRACK_URL, loadedTrack.url.absoluteString)
        XCTAssertEqual(TRACK_NAME, loadedTrack.name)
    }
    
    /// Tests that an existing track is loaded via fallback name.
    func testLoadTrackWithName() throws {
        try data.executeSql(query: String(format: "INSERT INTO Tracks (url, name) VALUES ('notTest', '%@')", TRACK_NAME), errorMessage: "")
        
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
    
    /// Tests that escapeStringForDb() escapes single quotes.
    func testEscapeStringForDb() {
        XCTAssertEqual("Let''s Go", data.escapeStringForDb("Let's Go"))
    }
    
    class TestMPMediaItem: MPMediaItem {
        
        var _assetURL: URL? = URL(string: TRACK_URL)
        var _title: String? = TRACK_NAME
        
        override init() {
            super.init()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override var assetURL: URL? {
            get {
                return _assetURL
            }
        }
        
        override var title: String? {
            get {
                return _title
            }
        }
    }
}
