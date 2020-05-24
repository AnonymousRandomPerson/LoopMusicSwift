/// Generic base class for a setting view. Uses a two-class hierarchy to get around limitations with generic in Swift.
class BaseSettingViewGeneric<Setting, SettingModifier:AnyObject> : BaseSettingView {
    
    /// Pointer to the raw setting value to display and update.
    var setting: UnsafeMutablePointer<Setting>
    /// UI view element used to change the setting value.
    var settingModifier: SettingModifier!
    
    /// Initializes a setting view.
    /// - parameter setting: Pointer to the raw setting value to display and update.
    /// - parameter setting: UI view element used to change the setting value.
    init(setting: UnsafeMutablePointer<Setting>, settingModifier: SettingModifier!) {
        self.setting = setting
        self.settingModifier = settingModifier
    }
    
    /// Gets the current value of the setting.
    /// - returns: Current value of the setting.
    func fetchSettingFromModifier() -> Setting {
        return setting.pointee
    }
    
    override func updateSetting() {
        setting.pointee = fetchSettingFromModifier()
    }
    
    override func hashValue() -> Int {
        return ObjectIdentifier(settingModifier).hashValue
    }
}
