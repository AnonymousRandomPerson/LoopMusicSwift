import UIKit

/// Setting view for an optional integer value controlled by a text field.
class IntOptionalSettingView: BaseSettingViewGeneric<Int?, UITextField> {

    override func displaySetting() {
        if let number = setting.pointee {
            settingModifier.text = String(number)
        }
    }

    override func fetchSettingFromModifier() -> Int? {
        if let text = settingModifier.text, let number = Int(text) {
            return number
        }
        return nil
    }
}
