import XCTest
@testable import LoopMusic

/// Tests music settings.
class MusicSettingsTests: XCTestCase {
    
    var settings: MusicSettings = MusicSettings.settings
    let TEST_TRACK: MusicTrack = MusicTrack(url: URL(fileURLWithPath: ""), name: "", loopStart: 5, loopEnd: 20, volumeMultiplier: 1)
    let REPEAT_LENGTH: Double = 15

    /// Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        settings.shuffleSetting = ShuffleSetting.none
        settings.shuffleTime = nil
        settings.shuffleRepeats = nil
        settings.shuffleTimeVariance = nil
        settings.shuffleRepeatsVariance = nil
        settings.minShuffleTime = nil
        settings.minShuffleRepeats = nil
        settings.maxShuffleTime = nil
        settings.maxShuffleRepeats = nil
    }

    /// Put teardown code here. This method is called after the invocation of each test method in the class.
    override func tearDown() {
    }

    /// Tests that calculateShuffleTime() returns nil on no shuffle.
    func testCalculateShuffleTimeWithNone() {
        settings.shuffleTime = 1
        settings.shuffleRepeats = 1
        XCTAssertNil(settings.calculateShuffleTime(track: TEST_TRACK))
    }

    /// Tests that calculateShuffleTime() returns nil on time shuffle if the shuffle time is not configured.
    func testCalculateShuffleTimeWithUnconfiguredTime() {
        settings.shuffleSetting = ShuffleSetting.time
        XCTAssertNil(settings.calculateShuffleTime(track: TEST_TRACK))
    }

    /// Tests that calculateShuffleTime() returns the shuffle time on time shuffle.
    func testCalculateShuffleTimeWithTime() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 5
        XCTAssertEqual(300, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() returns nil on repeats shuffle if the shuffle repeats setting is not configured.
    func testCalculateShuffleTimeWithUnconfiguredRepeats() {
        settings.shuffleSetting = ShuffleSetting.repeats
        XCTAssertNil(settings.calculateShuffleTime(track: TEST_TRACK))
    }

    /// Tests that calculateShuffleTime() returns the correct shuffle time on repeats shuffle.
    func testCalculateShuffleTimeWithRepeats() {
        settings.shuffleSetting = ShuffleSetting.repeats
        settings.shuffleRepeats = 2
        XCTAssertEqual(35, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateShuffleVariance() returns nil if no variance is configured.
    func testCalculateShuffleVarianceUnconfigured() {
        XCTAssertNil(settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH))
    }
    
    /// Tests that calculateShuffleVariance() returns the configured time variance.
    func testCalculateShuffleVarianceWithTimeVariance() {
        settings.shuffleTimeVariance = 1
        XCTAssertEqual(60, settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateShuffleVariance() returns the configured repeats variance.
    func testCalculateShuffleVarianceWithRepeatsVariance() {
        settings.shuffleRepeatsVariance = 2
        XCTAssertEqual(30, settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateShuffleVariance() prioritizes time variance over repeats.
    func testCalculateShuffleVarianceWithBothVariance() {
        settings.shuffleTimeVariance = 5
        settings.shuffleRepeatsVariance = 2
        XCTAssertEqual(300, settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() returns nil if no min time is configured.
    func testCalculateMinShuffleTimeUnconfigured() {
        XCTAssertNil(settings.calculateMinShuffleTime(repeatLength: REPEAT_LENGTH))
    }
    
    /// Tests that calculateMinShuffleTime() returns the configured min time.
    func testCalculateMinShuffleTimeWithMinTime() {
        settings.minShuffleTime = 5
        XCTAssertEqual(300, settings.calculateMinShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() returns the configured min repeats.
    func testCalculateMinShuffleTimeWithMinRepeats() {
        settings.minShuffleRepeats = 2
        XCTAssertEqual(30, settings.calculateMinShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() uses the higher of min time and repeats.
    func testCalculateMinShuffleTimeWithHigherMinTime() {
        settings.minShuffleTime = 5
        settings.minShuffleRepeats = 2
        XCTAssertEqual(300, settings.calculateMinShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() uses the higher of min time and repeats.
    func testCalculateMinShuffleTimeWithHigherMinRepeats() {
        settings.minShuffleTime = 1
        settings.minShuffleRepeats = 5
        XCTAssertEqual(75, settings.calculateMinShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() returns nil if no max time is configured.
    func testCalculateMaxShuffleTimeUnconfigured() {
        XCTAssertNil(settings.calculateMaxShuffleTime(repeatLength: REPEAT_LENGTH))
    }
    
    /// Tests that calculateMaxShuffleTime() returns the configured max time.
    func testCalculateMaxShuffleTimeWithMaxTime() {
        settings.maxShuffleTime = 5
        XCTAssertEqual(300, settings.calculateMaxShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() returns the configured max repeats.
    func testCalculateMaxShuffleTimeWithMaxRepeats() {
        settings.maxShuffleRepeats = 2
        XCTAssertEqual(30, settings.calculateMaxShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() uses the lower of max time and repeats.
    func testCalculateMaxShuffleTimeWithLowerMaxTime() {
        settings.maxShuffleTime = 1
        settings.maxShuffleRepeats = 5
        XCTAssertEqual(60, settings.calculateMaxShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() uses the lower of max time and repeats.
    func testCalculateMaxShuffleTimeWithLowerMaxRepeats() {
        settings.maxShuffleTime = 1
        settings.maxShuffleRepeats = 2
        XCTAssertEqual(30, settings.calculateMaxShuffleTime(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() raises the shuffle time to the min time if shuffle time is lower.
    func testCalculateShuffleTimeWithMinTime() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 1
        settings.minShuffleRepeats = 5
        XCTAssertEqual(75, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() lowers the shuffle time to the max time if shuffle time is higher.
    func testCalculateShuffleTimeWithMaxTime() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 1
        settings.maxShuffleRepeats = 2
        XCTAssertEqual(30, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() returns a shuffle time within the variance range on time shuffle if time variance is set.
    func testCalculateShuffleTimeWithTimeVariance() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 2
        settings.shuffleTimeVariance = 1
        let shuffleTime = settings.calculateShuffleTime(track: TEST_TRACK)!
        XCTAssertGreaterThanOrEqual(60, shuffleTime)
        XCTAssertLessThanOrEqual(180, shuffleTime)
    }
}
