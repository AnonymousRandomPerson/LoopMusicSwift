/// An error containing a message describing the error.
struct MessageError: Error {
    
    /// Message describing the error.
    let message: String
    
    /// Initializes an error with a message.
    /// - parameter message: Message describing the error.
    init(_ message: String) {
        self.message = message
    }
    
    /// Initializes an error with a message and an internal status code.
    /// - parameter message: Message describing the error.
    /// - parameter statusCode: Status code of the failed operation.
    init(message: String, statusCode: Int32) {
        self.message = String(format: "%@ Status code: %d", message, statusCode)
    }
    
    /// Gets the message describing the error. Mirrors NSError's localizedDescription().
    /// - returns: Message describing the error.
    public var localizedDescription: String {
        return message
    }
}
