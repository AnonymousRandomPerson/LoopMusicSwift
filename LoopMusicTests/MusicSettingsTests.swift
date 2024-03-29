import XCTest
@testable import LoopMusic

/// Tests music settings.
class MusicSettingsTests: XCTestCase {
    
    /// Music settings instance.
    var settings: MusicSettings = MusicSettings.settings
    /// Constant test music track.
    let TEST_TRACK: MusicTrack = MusicTrack(id: 0, url: URL(fileURLWithPath: ""), name: "", loopStart: 5, loopEnd: 20, volumeMultiplier: 1)
    
    /// Pre-calculated repeat offset of TEST_TRACK
    let REPEAT_OFFSET: Double = 5
    /// Pre-calculated repeat length of TEST_TRACK.
    let REPEAT_LENGTH: Double = 15
    
    /// Settings file to write to for testing.
    let TEST_SETTINGS_FILE: String = "TestSettings.plist"
    var testSettingsUrl: URL?

    override func setUp() {
        do {
            testSettingsUrl = try FileUtils.getFileUrl(fileName: TEST_SETTINGS_FILE)
        } catch {
            XCTFail(String(format: "Failed to load settings file. %@", error.localizedDescription))
        }
        settings.settingsFileName = TEST_SETTINGS_FILE
        settings.currentPlaylist = MediaPlayerUtils.ALL_TRACKS_PLAYLIST
        settings.playOnInit = false
        settings.masterVolume = 0
        settings.defaultRelativeVolume = 0
        settings.volumeNormalizationLevel = nil
        settings.shuffleSetting = ShuffleSetting.none
        settings.fadeDuration = nil
        settings.shuffleHistoryLength = nil
        settings.shuffleTime = nil
        settings.shuffleRepeats = nil
        settings.shuffleTimeVariance = nil
        settings.shuffleRepeatsVariance = nil
        settings.minShuffleTime = nil
        settings.minShuffleRepeats = nil
        settings.maxShuffleTime = nil
        settings.maxShuffleRepeats = nil
    }

    override func tearDown() {
        do {
            if FileManager.default.fileExists(atPath: testSettingsUrl!.path) {
                try FileManager.default.removeItem(at: testSettingsUrl!)
            }
        } catch {
            XCTFail(String(format: "Failed to clean up settings file. %@", error.localizedDescription))
        }
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
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTimeVariance = 1
        XCTAssertEqual(60, settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateShuffleVariance() returns the configured repeats variance.
    func testCalculateShuffleVarianceWithRepeatsVariance() {
        settings.shuffleSetting = ShuffleSetting.repeats
        settings.shuffleRepeatsVariance = 2
        XCTAssertEqual(30, settings.calculateShuffleVariance(repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() returns nil if shuffle setting is none.
    func testCalculateMinShuffleTimeNone() {
        XCTAssertNil(settings.calculateMinShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH))
    }
    
    /// Tests that calculateMinShuffleTime() returns the configured min time.
    func testCalculateMinShuffleTimeWithMinTime() {
        settings.minShuffleTime = 5
        settings.minShuffleRepeats = 2
        settings.shuffleSetting = ShuffleSetting.repeats
        XCTAssertEqual(300, settings.calculateMinShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMinShuffleTime() returns the configured min repeats.
    func testCalculateMinShuffleTimeWithMinRepeats() {
        settings.minShuffleTime = 5
        settings.minShuffleRepeats = 2
        settings.shuffleSetting = ShuffleSetting.time
        XCTAssertEqual(35, settings.calculateMinShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() returns nil if shuffle setting is none.
    func testCalculateMaxShuffleTimeNone() {
        settings.maxShuffleTime = 5
        settings.maxShuffleRepeats = 2
        XCTAssertNil(settings.calculateMaxShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH))
    }
    
    /// Tests that calculateMaxShuffleTime() returns the configured max time.
    func testCalculateMaxShuffleTimeWithMaxTime() {
        settings.maxShuffleTime = 5
        settings.maxShuffleRepeats = 2
        settings.shuffleSetting = ShuffleSetting.repeats
        XCTAssertEqual(300, settings.calculateMaxShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }
    
    /// Tests that calculateMaxShuffleTime() returns the configured max repeats.
    func testCalculateMaxShuffleTimeWithMaxRepeats() {
        settings.maxShuffleTime = 5
        settings.maxShuffleRepeats = 2
        settings.shuffleSetting = ShuffleSetting.time
        XCTAssertEqual(35, settings.calculateMaxShuffleTime(repeatOffset: REPEAT_OFFSET, repeatLength: REPEAT_LENGTH)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() raises the shuffle time to the min time if shuffle time is lower.
    func testCalculateShuffleTimeWithMinTime() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 1
        settings.minShuffleRepeats = 5
        XCTAssertEqual(80, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() lowers the shuffle time to the max time if shuffle time is higher.
    func testCalculateShuffleTimeWithMaxTime() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 1
        settings.maxShuffleRepeats = 2
        XCTAssertEqual(35, settings.calculateShuffleTime(track: TEST_TRACK)!, accuracy: EPSILON)
    }

    /// Tests that calculateShuffleTime() returns a shuffle time within the variance range on time shuffle if time variance is set.
    func testCalculateShuffleTimeWithTimeVariance() {
        settings.shuffleSetting = ShuffleSetting.time
        settings.shuffleTime = 2
        settings.shuffleTimeVariance = 1
        /// Shuffle time to assert on.
        let shuffleTime = settings.calculateShuffleTime(track: TEST_TRACK)!
        XCTAssertLessThanOrEqual(60, shuffleTime)
        XCTAssertGreaterThanOrEqual(180, shuffleTime)
    }
    
    /// Tests that the settings file can be loaded.
    func testLoadSettingsFile() throws {
        let encoder: PropertyListEncoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        var settingsFile: MusicSettingsCodable = MusicSettingsCodable()
        settingsFile.playOnInit = true
        settingsFile.masterVolume = 1
        settingsFile.defaultRelativeVolume = 2
        settingsFile.volumeNormalizationLevel = -23
        settingsFile.shuffleSetting = "time"
        settingsFile.fadeDuration = 9
        settingsFile.shuffleHistoryLength = 20
        settingsFile.shuffleTime = 1
        settingsFile.shuffleTimeVariance = 2
        settingsFile.minShuffleRepeats = 3
        settingsFile.maxShuffleRepeats = 4
        settingsFile.shuffleRepeats = 5
        settingsFile.shuffleRepeatsVariance = 6
        settingsFile.minShuffleTime = 7
        settingsFile.maxShuffleTime = 8
        try encoder.encode(settingsFile).write(to: testSettingsUrl!)
        
        try settings.loadSettingsFile()
        XCTAssertTrue(settings.currentPlaylist === MediaPlayerUtils.ALL_TRACKS_PLAYLIST)
        XCTAssertTrue(settings.playOnInit)
        XCTAssertEqual(settings.masterVolume, 1, accuracy: EPSILON)
        XCTAssertEqual(settings.defaultRelativeVolume, 2, accuracy: EPSILON)
        XCTAssertEqual(settings.volumeNormalizationLevel!, -23, accuracy: EPSILON)
        XCTAssertEqual(settings.shuffleSetting, ShuffleSetting.time)
        XCTAssertEqual(settings.fadeDuration!, 9, accuracy: EPSILON)
        XCTAssertEqual(settings.shuffleHistoryLength!, 20)
        XCTAssertEqual(settings.shuffleTime!, 1, accuracy: EPSILON)
        XCTAssertEqual(settings.shuffleTimeVariance!, 2, accuracy: EPSILON)
        XCTAssertEqual(settings.minShuffleRepeats!, 3, accuracy: EPSILON)
        XCTAssertEqual(settings.maxShuffleRepeats!, 4, accuracy: EPSILON)
        XCTAssertEqual(settings.shuffleRepeats!, 5, accuracy: EPSILON)
        XCTAssertEqual(settings.shuffleRepeatsVariance!, 6, accuracy: EPSILON)
        XCTAssertEqual(settings.minShuffleTime!, 7, accuracy: EPSILON)
        XCTAssertEqual(settings.maxShuffleTime!, 8, accuracy: EPSILON)
    }
    
    /// Tests that the settings file can be saved.
    func testSaveSettingsFile() throws {
        settings.playOnInit = true
        settings.masterVolume = 1
        settings.defaultRelativeVolume = 2
        settings.volumeNormalizationLevel = -23
        settings.shuffleSetting = ShuffleSetting.time
        settings.fadeDuration = 9
        settings.shuffleHistoryLength = 20
        settings.shuffleTime = 1
        settings.shuffleTimeVariance = 2
        settings.minShuffleRepeats = 3
        settings.maxShuffleRepeats = 4
        settings.shuffleRepeats = 5
        settings.shuffleRepeatsVariance = 6
        settings.minShuffleTime = 7
        settings.maxShuffleTime = 8
        
        try settings.saveSettingsFile()
        
        let settingsFile: MusicSettingsCodable = try PropertyListDecoder().decode(MusicSettingsCodable.self, from: try Data(contentsOf: testSettingsUrl!))
        
        XCTAssertNil(settingsFile.currentPlaylist)
        XCTAssertTrue(settingsFile.playOnInit)
        XCTAssertEqual(settingsFile.masterVolume, 1, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.defaultRelativeVolume, 2, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.volumeNormalizationLevel!, -23, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.shuffleSetting, "time")
        XCTAssertEqual(settingsFile.fadeDuration!, 9, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.shuffleHistoryLength!, 20)
        XCTAssertEqual(settingsFile.shuffleTime!, 1, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.shuffleTimeVariance!, 2, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.minShuffleRepeats!, 3, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.maxShuffleRepeats!, 4, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.shuffleRepeats!, 5, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.shuffleRepeatsVariance!, 6, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.minShuffleTime!, 7, accuracy: EPSILON)
        XCTAssertEqual(settingsFile.maxShuffleTime!, 8, accuracy: EPSILON)
    }
    
    /// Tests that the settings file is created when attempting to load settings without a file.
    func testSaveSettingsFileOnLoad() throws {
        try settings.loadSettingsFile()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testSettingsUrl!.path))
        let settingsFile: MusicSettingsCodable = try PropertyListDecoder().decode(MusicSettingsCodable.self, from: try Data(contentsOf: testSettingsUrl!))
        
        XCTAssertFalse(settingsFile.playOnInit)
    }
}
