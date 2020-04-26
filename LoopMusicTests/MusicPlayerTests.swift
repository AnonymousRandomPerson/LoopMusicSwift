import XCTest
@testable import LoopMusic

/// Tests the music player.
class MusicPlayerTests: XCTestCase {
    
    var musicPlayer: MusicPlayer!

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
        XCTAssertEqual(0, musicPlayer.currentTrack.volumeMultiplier)
    }
}
