import XCTest
@testable import LoopMusic

/// Tests the music player.
class MusicPlayerTests: XCTestCase {
    
    /// Music player instance for testing.
    var musicPlayer: MusicPlayer!

    override func setUp() {
        musicPlayer = MusicPlayer()
    }

    override func tearDown() {
    }

    /// Tests that a blank track is initialized in the music player when it is created.
    func testInitMusicPlayer() {
        XCTAssertEqual("/", musicPlayer.currentTrack.url.path)
        XCTAssertEqual("", musicPlayer.currentTrack.name)
        XCTAssertEqual(0, musicPlayer.currentTrack.loopStart)
        XCTAssertEqual(0, musicPlayer.currentTrack.loopEnd)
        XCTAssertEqual(0, musicPlayer.currentTrack.volumeMultiplier)
    }
}
