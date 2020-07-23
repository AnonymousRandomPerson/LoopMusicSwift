import SQLite3
import XCTest
@testable import LoopMusic

/// Used to import an external database into the app's database.
class DataImporter: XCTestCase {

    /// Music data instance.
    let data: MusicData = MusicData.data

    override func setUp() {
    }

    override func tearDown() {
    }

    /// To run, place the new database in the LoopMusicTests/Utils folder and rename it to "TracksNew.db". Add the file with target membership in LoopMusicTests. Then add "test" in front of this function's name and run it.
    /// WARNING: This will replace the contents of the Tracks table in the app's database with the new data.
    func testimportDb() throws {
        try data.closeConnection()
        /// New database URL.
        let dbUrl: URL = Bundle(for: DataMigrator.self).url(forResource: "TracksNew", withExtension: "db")!
        try data.openConnection(dbUrl: dbUrl)

        /// Query for inserting tracks into the new database.
        var insertQuery: String = "INSERT INTO Tracks (url, name, loopStart, loopEnd, volumeMultiplier) VALUES "
        /// True for the first track. Used for comma formatting.
        var first: Bool = true

        try data.executeSql(
            query: "SELECT url, name, loopStart, loopEnd, volumeMultiplier FROM Tracks",
            stepCallback: {(statement: OpaquePointer?) -> Void in
                if (first) {
                    first = false
                } else {
                    insertQuery += ","
                }
                /// Current track name.
                let name: String = self.data.escapeStringForDb(String(cString: sqlite3_column_text(statement, 1)))
                insertQuery += String(format: "('%s', '%@', %f, %f, %f)", sqlite3_column_text(statement, 0), name, sqlite3_column_double(statement, 2), sqlite3_column_double(statement, 3), sqlite3_column_double(statement, 4))
            },
            noResultCallback: nil,
            errorMessage: String(format: "Failed to select tracks."))

        try data.closeConnection()
        try data.openConnection()
        try data.executeSql(query: "DELETE FROM Tracks", errorMessage: "Failed to clear tracks table.")
        try data.executeSql(query: insertQuery, errorMessage: "Failed to insert imported records.")
    }
}
