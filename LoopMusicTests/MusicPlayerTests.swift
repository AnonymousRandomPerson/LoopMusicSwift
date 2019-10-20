import XCTest
@testable import LoopMusic

/// Tests the music player.
class MusicPlayerTests: XCTestCase {
    
    var musicPlayer: MusicPlayer!
    let TRACK_ID: String = "Thing"

    /// Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        musicPlayer = MusicPlayer()
    }

    /// Put teardown code here. This method is called after the invocation of each test method in the class.
    override func tearDown() {
    }

    /// Tests that a blank track is initialized in the music player when it is created.
    func testInitMusicPlayer() {
        XCTAssertEqual("/", musicPlayer.currentTrack.url.path)
        XCTAssertEqual("", musicPlayer.currentTrack.name)
        XCTAssertEqual(0, musicPlayer.currentTrack.loopStart)
        XCTAssertEqual(0, musicPlayer.currentTrack.loopEnd)
    }
    
    /// Tests that a track is loaded into the music player using loadTrack().
    func testLoadTrack() throws {
        try musicPlayer.loadTrack(trackId: TRACK_ID)
        XCTAssertEqual("DL3 Minigame", musicPlayer.currentTrack.name)
        XCTAssertFalse(musicPlayer.playing)
    }
    
    /// Tests that the music player starts playing using playTrack() and stops using stopTrack().
    func testPlayStopTrack() throws {
        try musicPlayer.loadTrack(trackId: TRACK_ID)
        try musicPlayer.playTrack()
        XCTAssertTrue(musicPlayer.playing)
        try musicPlayer.stopTrack()
        XCTAssertFalse(musicPlayer.playing)
    }
}
