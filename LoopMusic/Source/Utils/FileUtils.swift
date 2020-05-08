/// Utility functions for file access.
class FileUtils {
    
    /// Gets the URL of a file.
    /// - parameter fileName: The file to get a URL for.
    static func getFileUrl(fileName: String) throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
    }
}
