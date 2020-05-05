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

    /// To run, place the old database in the test folder and rename it to "TracksOld.db". Then add "test" in front of this function's name and run it.
    /// WARNING: This will replace the contents of the Tracks table in the app's database with the migrated data.
    func migrateOldDb() throws {
        try data.closeConnection()
        /// Old database URL.
        let dbUrl: URL = Bundle(for: DataMigrator.self).url(forResource: "TracksOld", withExtension: "db")!
        try data.openConnection(dbUrl: dbUrl)
        
        /// Query for inserting tracks into the new database.
        var insertQuery: String = "INSERT INTO Tracks (url, name, loopStart, loopEnd, volumeMultiplier) VALUES "
        /// True for the first track. Used for comma formatting.
        var first: Bool = true
        
        try data.executeSql(
            query: "SELECT name, loopstart, loopend, volume, url FROM Tracks",
            stepCallback: {(statement: OpaquePointer?) -> Void in
                if (first) {
                    first = false
                } else {
                    insertQuery += ","
                }
                /// Current track name.
                let name: String = self.data.escapeStringForDb(String(cString: sqlite3_column_text(statement, 0)))
                insertQuery += String(format: "('%s', '%@', %f, %f, %f)", sqlite3_column_text(statement, 4), name, sqlite3_column_double(statement, 1), sqlite3_column_double(statement, 2), sqlite3_column_double(statement, 3))
            },
            noResultCallback: nil,
            errorMessage: String(format: "Failed to select tracks."))
        
        try data.closeConnection()
        try data.openConnection()
        
        try data.executeSql(query: "DELETE FROM Tracks", errorMessage: "Failed to clear tracks table.")
        try data.executeSql(query: insertQuery, errorMessage: "Failed to insert migrated records.")
    }
}
