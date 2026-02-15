import SQLite3
import XCTest
@testable import LoopMusic

/// Used to import an external database into the app's database.
class DataLoopSyncer: XCTestCase {

    /// Music data instance.
    let data: MusicData = MusicData.data

    override func setUp() {
    }

    override func tearDown() {
    }

    /// To run, place the new database in the LoopMusicTests/Utils folder and rename it to "TracksNew.db". Add the file with target membership in LoopMusicTests. Then add "test" in front of this function's name and run it.
    /// WARNING: This will replace the contents of the Tracks table in the app's database with the new data.
    func syncDb() throws {
        try data.closeConnection()
        /// New database URL.
        let dbUrl: URL = Bundle(for: DataMigrator.self).url(forResource: "TracksNew", withExtension: "db")!
        try data.openConnection(dbUrl: dbUrl)

        /// Query for updating tracks in the new database.
        var updateQuery: String = ""

        try data.executeSql(
            query: "SELECT name, loopStart, loopEnd, volumeMultiplier, loopInShuffle FROM Tracks",
            stepCallback: {(statement: OpaquePointer?) -> Void in
                /// Current track name.
                let name: String = self.data.escapeStringForDb(String(cString: sqlite3_column_text(statement, 0)))
                updateQuery += String(format: "UPDATE Tracks SET loopStart = %f, loopEnd = %f, volumeMultiplier = %f, loopInShuffle = %d WHERE name = '%@';", sqlite3_column_double(statement, 1), sqlite3_column_double(statement, 2), sqlite3_column_double(statement, 3), sqlite3_column_int(statement, 4), name)
            },
            noResultCallback: nil,
            errorMessage: String(format: "Failed to select tracks."))

        try data.closeConnection()
        try data.openConnection()
        try data.executeSql(query: updateQuery, errorMessage: "Failed to update records.")
    }
}
