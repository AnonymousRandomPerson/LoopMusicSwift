import SQLite3
import XCTest
@testable import LoopMusic

/// Used to clean unwanted rows from the database.
class DataCleaner: XCTestCase {

    /// Music data instance.
    let data: MusicData = MusicData.data
    /// List of table IDs to drop.
    var idsToRemove: [Int] = []

    override func setUp() {
    }

    override func tearDown() {
    }

    /// To run, fill the idsToRemove field with the appropriate table IDs. Then add "test" in front of this function's name and run it.
    /// WARNING: This will remove the specified rows of the Tracks table in the app's database.
    func cleanDb() throws {
        // Do nothing if empty
        if idsToRemove.count == 0 {
            return
        }

        let deleteQuery: String = "DELETE FROM Tracks WHERE id IN (\(idsToRemove.map(String.init).joined(separator: ", ")))"
        try data.executeSql(query: deleteQuery, errorMessage: "Failed to clean tracks table.")
    }
}
