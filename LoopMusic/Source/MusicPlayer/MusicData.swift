import Foundation
import MediaPlayer
import SQLite3

/// Interfaces with the SQLite database that stores track metadata.
class MusicData {
    
    /// Singleton instance.
    static let data: MusicData = MusicData()
    
    /// Database connection.
    private var db: OpaquePointer?
    /// True if the database connection is open.
    private var open: Bool = false

    /// Private constructor for singleton.
    private init() {
    }
    
    /// Opens the connection to the database.
    func openConnection() throws {
        try openConnection(dbUrl: try FileUtils.getFileUrl(fileName: "Tracks.db"))
    }
    
    /// Opens the connection to the database.
    /// - parameter dbName: The name of the database file to load.
    func openConnection(dbUrl: URL) throws {
        if open {
            return
        }
        
        try validateSqlResult(statusCode: sqlite3_open(dbUrl.path, &db), errorMessage: "Failed to open DB.")
        
        try executeSql(query: String(format: "CREATE TABLE IF NOT EXISTS Tracks (id INTEGER PRIMARY KEY, url TEXT NOT NULL, name TEXT NOT NULL, loopStart NUMERIC DEFAULT 0, loopEnd NUMERIC DEFAULT 0, volumeMultiplier NUMERIC DEFAULT %d)", MusicTrack.DEFAULT_VOLUME_MULTIPLIER),
                       errorMessage: "Failed to create tracks table.")
        
        open = true
    }
    
    /// Closes the currently open connection to the database.
    func closeConnection() throws {
        if !open {
            return
        }
        
        try validateSqlResult(statusCode: sqlite3_close_v2(db), errorMessage: "Failed to close DB.")
        
        open = false
    }
    
    /// Loads track metadata corresponding with the given media item.
    /// - parameter mediaItem: The media item to load metadata for.
    func loadTrack(mediaItem: MPMediaItem) throws -> MusicTrack {
        /// The track to return.
        var track: MusicTrack = MusicTrack.BLANK_MUSIC_TRACK
        if let trackURL: URL = mediaItem.assetURL, let trackName: String = mediaItem.title {
            /// Track name escaped for SQL queries.
            let escapedTrackName = self.escapeStringForDb(trackName)
            let trackCallback = {(statement: OpaquePointer?) -> Void in
                track = MusicTrack(
                    id: sqlite3_column_int64(statement, 4),
                    url: trackURL,
                    name: trackName,
                    loopStart: sqlite3_column_double(statement, 0),
                    loopEnd: sqlite3_column_double(statement, 1),
                    volumeMultiplier: sqlite3_column_double(statement, 2))
                let dbTrackName: String = String(cString: sqlite3_column_text(statement, 3))
                if dbTrackName != trackName {
                    // If the media item name has changed since last loaded from the database, update it.
                    // This can happen if the item is renamed outside the app.
                    try self.executeSql(query: String(format: "UPDATE Tracks SET name = '%@' WHERE id = '%i'", escapedTrackName, track.id),
                                        errorMessage: String(format: "Failed to update name for %@", trackName))
                }
            }
            try executeSql(
                query: String(format: "SELECT loopStart, loopEnd, volumeMultiplier, name, id FROM Tracks WHERE url = '%@'", trackURL.absoluteString),
                stepCallback: trackCallback,
                noResultCallback: {() -> Void in
                    // Try to fallback on name. If the track is changed at all, the URL may change.
                    try self.executeSql(
                        query: String(format: "SELECT loopStart, loopEnd, volumeMultiplier, id FROM Tracks WHERE name = '%@'", escapedTrackName),
                        stepCallback: {(statement: OpaquePointer?) -> Void in
                            // Update the stored track URL if a name match is found.
                            try trackCallback(statement)
                            try self.executeSql(query: String(format: "UPDATE Tracks SET url = '%@' WHERE id = '%i'", trackURL.absoluteString, sqlite3_column_int(statement, 3)),
                                                errorMessage: String(format: "Failed to update URL for %@", trackName))
                        },
                        noResultCallback: {() -> Void in
                            // Save track as new if not found.
                            try self.executeSql(
                                query: String(format: "INSERT INTO Tracks (url, name, volumeMultiplier) VALUES ('%@', '%@', '%f')", trackURL.absoluteString, escapedTrackName, MusicSettings.settings.defaultRelativeVolume),
                                lastInsertCallback: {(id: Int64) -> Void in
                                    track = MusicTrack(
                                        id: id,
                                        url: trackURL,
                                        name: trackName,
                                        loopStart: 0,
                                        loopEnd: 0,
                                        volumeMultiplier: MusicSettings.settings.defaultRelativeVolume)
                                },
                                errorMessage: String(format: "Failed to save %@ as new track.", trackName))
                            
                        },
                        errorMessage: String(format: "Failed to load track: %@.", trackName))
                },
                errorMessage: String(format: "Failed to load track: %@.", trackName))
        } else {
            throw MessageError(String(format: "Attempted to load track without URL or title."))
        }
        return track
    }
    
    /// Updates the volume multiplier for a track.
    /// - parameter track: The track to update.
    func updateVolumeMultiplier(track: MusicTrack) throws {
        try executeSql(query: String(format: "UPDATE Tracks SET volumeMultiplier = '%f' WHERE id = '%i'", track.volumeMultiplier, track.id), errorMessage: String(format: "Failed to update volume multiplier for track: %@.", track.name))
    }
    
    /// Updates the loop points for a track.
    /// - parameter track: The track to update.
    func updateLoopPoints(track: MusicTrack) throws {
        try executeSql(query: String(format: "UPDATE Tracks SET loopStart = '%f', loopEnd = '%f' WHERE id = '%i'", track.loopStart, track.loopEnd, track.id), errorMessage: String(format: "Failed to update loop points for track: %@.", track.name))
    }
    
    /// Throws a MessageError containing the SQL error message from sqlite3_errmsg() if a SQL call results in an error.
    /// - parameter statusCode: The status code returned from the latest SQL query.
    /// - parameter errorMessage: The main body of the error message in the MessageError.
    private func validateSqlResult(statusCode: Int32, errorMessage: String) throws {
        if statusCode != SQLITE_OK && statusCode != SQLITE_DONE && statusCode != SQLITE_ROW {
            throw MessageError(String(format: "%@ SQL error message: %@.", errorMessage, String(cString: sqlite3_errmsg(db))), statusCode)
        }
    }
    
    /// Executes a SQL query.
    /// - parameter query: The SQL query string to execute.
    /// - parameter errorMessage: The error message to display if the SQL query fails.
    func executeSql(query: String, errorMessage: String) throws {
        try executeSql(query: query, stepCallback: nil, noResultCallback: nil, errorMessage: errorMessage)
    }
    
    /// Executes a SQL query.
    /// - parameter query: The SQL query string to execute.
    /// - parameter stepCallback: Callback for each row returned from the query.
    /// - parameter noResultCallback: Callback when there are no results from the query.
    /// - parameter errorMessage: The error message to display if the query fails.
    /// - returns: True if results were returned from the SQL query (e.g., non-empty SELECT).
    func executeSql(query: String, stepCallback: ((_: OpaquePointer?) throws -> Void)?, noResultCallback: (() throws -> Void)?, errorMessage: String) throws {
        try executeSql(query: query, stepCallback: stepCallback, noResultCallback: noResultCallback, lastInsertCallback: nil, errorMessage: errorMessage)
    }
    
    /// Executes a SQL query.
    /// - parameter query: The SQL query string to execute.
    /// - parameter lastInsertCallback: Callback for the last inserted index value.
    /// - parameter errorMessage: The error message to display if the query fails.
    /// - returns: True if results were returned from the SQL query (e.g., non-empty SELECT).
    func executeSql(query: String, lastInsertCallback: ((_: Int64) -> Void)?, errorMessage: String) throws {
        try executeSql(query: query, stepCallback: nil, noResultCallback: nil, lastInsertCallback: lastInsertCallback, errorMessage: errorMessage)
    }
    
    /// Executes a SQL query.
    /// - parameter query: The SQL query string to execute.
    /// - parameter stepCallback: Callback for each row returned from the query.
    /// - parameter noResultCallback: Callback when there are no results from the query.
    /// - parameter lastInsertCallback: Callback for the last inserted index value. 
    /// - parameter errorMessage: The error message to display if the query fails.
    /// - returns: True if results were returned from the SQL query (e.g., non-empty SELECT).
    func executeSql(query: String, stepCallback: ((_: OpaquePointer?) throws -> Void)?, noResultCallback: (() throws -> Void)?, lastInsertCallback: ((_: Int64) -> Void)?, errorMessage: String) throws {
        /// Error message if a SQL query has an error.
        var sqlErrorMessage: UnsafeMutablePointer<Int8>? = nil
        /// The status code returned from the latest SQL query.
        var execCode: Int32
        /// True if the SQL query returned a row.
        var hasResults: Bool = false
        if let stepCallback: (_: OpaquePointer?) throws -> Void = stepCallback {
            /// Prepared SQL statement.
            var statement: OpaquePointer? = nil
            execCode = sqlite3_prepare_v2(db, query, -1, &statement, nil)
            try validateSqlResult(statusCode: execCode, errorMessage: errorMessage)
            
            repeat {
                execCode = sqlite3_step(statement)
                try validateSqlResult(statusCode: execCode, errorMessage: errorMessage)
                
                if execCode == SQLITE_ROW {
                    hasResults = true
                    try stepCallback(statement)
                }
            } while execCode == SQLITE_ROW
            
            execCode = sqlite3_finalize(statement)
            try validateSqlResult(statusCode: execCode, errorMessage: errorMessage)
        } else {
            execCode = sqlite3_exec(db, query, nil, nil, &sqlErrorMessage)
        }
        
        if let lastInsertCallback: ((_: Int64) -> Void) = lastInsertCallback {
            lastInsertCallback(sqlite3_last_insert_rowid(db))
        }
        
        if let sqlErrorMessage: UnsafeMutablePointer<Int8> = sqlErrorMessage {
            let sqlError: String = String(cString: sqlErrorMessage)
            sqlite3_free(sqlErrorMessage)
            throw MessageError(String(format: "%@ SQL error message: %@.", errorMessage, sqlError), execCode)
        } else {
            try validateSqlResult(statusCode: execCode, errorMessage: errorMessage)
        }
        if !hasResults, let noResultCallback: () throws -> Void = noResultCallback {
            try noResultCallback()
        }
    }
    
    /// Escapes a string to write it to the database. This includes doubling-up single quotes.
    /// - parameter string: The string to escape.
    /// - returns: The escaped string.
    func escapeStringForDb(_ string: String) -> String {
        return string.replacingOccurrences(of: "'", with: "''")
    }
}
