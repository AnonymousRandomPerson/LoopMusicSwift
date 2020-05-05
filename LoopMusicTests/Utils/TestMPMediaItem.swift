import MediaPlayer

/// Mocks MPMediaItem for testing.
class TestMPMediaItem: MPMediaItem {
    
    /// Mock asset URL for testing.
    var _assetURL: URL? = URL(string: TRACK_URL)
    /// Mock item title for testing.
    var _title: String? = TRACK_NAME
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// Overrides asset URL with mock field.
    override var assetURL: URL? {
        get {
            return _assetURL
        }
    }
    
    /// Overrides title with mock field.
    override var title: String? {
        get {
            return _title
        }
    }
}
