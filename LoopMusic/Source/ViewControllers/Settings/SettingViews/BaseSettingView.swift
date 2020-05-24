/// Base class for a setting view, used to link a setting value and the UI view element used to change it.
class BaseSettingView {
    
    /// Loads the setting value into the view element.
    func displaySetting() {
    }
    
    /// Updates the raw setting value after the view element changes.
    func updateSetting() {
    }
    
    /// Gets the hash value of the setting view for dictionaries.
    func hashValue() -> Int {
        return ObjectIdentifier(self).hashValue
    }
}
