import SQLite3
import XCTest
@testable import LoopMusic

/// Used to migrate a database from the old app schema to the current schema.
class DataMigrator: XCTestCase {
    
    /// Music data instance.
    let data: MusicData = MusicData.data
    
    override func setUp() {
    }
    
    override func tearDown() {
    }

    /// To run, add "test" in front of this function's name and run it.
    func migrateOldDb() throws {
        try data.openConnection()
        
        try data.executeSql(
            query: "ALTER TABLE Tracks ADD COLUMN loopInShuffle INTEGER DEFAULT TRUE",
            errorMessage: String(format: "Failed to migrate table."))
        
        try data.closeConnection()
    }
}
