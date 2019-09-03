/// An error containing a message describing the error.
struct MessageError: Error {
    
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return message
    }
}
