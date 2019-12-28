/// An error containing a message describing the error.
struct MessageError: Error {
    
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    init(message: String, statusCode: Int32) {
        self.message = String(format: "%@ Status code: %d", message, statusCode)
    }
    
    public var localizedDescription: String {
        return message
    }
}
