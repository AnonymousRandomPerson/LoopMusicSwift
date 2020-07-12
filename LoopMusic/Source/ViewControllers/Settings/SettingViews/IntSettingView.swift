import UIKit

/// Setting view for an integer value controlled by a text field.
class IntSettingView: BaseSettingViewGeneric<Int, UITextField> {
    
    override func displaySetting() {
        settingModifier.text = String(setting.pointee)
    }
    
    override func fetchSettingFromModifier() -> Int {
        if let text = settingModifier.text, let number = Int(text) {
            return number
        }
        return 0
    }
}
