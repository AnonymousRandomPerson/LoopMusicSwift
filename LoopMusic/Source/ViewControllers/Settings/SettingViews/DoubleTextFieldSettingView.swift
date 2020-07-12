import UIKit

/// Setting view for a decimal value controlled by a text field.
class DoubleTextFieldSettingView: BaseSettingViewGeneric<Double, UITextField> {
    
    override func displaySetting() {
        settingModifier.text = NumberUtils.formatNumber(setting.pointee)
    }
    
    override func fetchSettingFromModifier() -> Double {
        if let text = settingModifier.text, let number = Double(text) {
            return number
        }
        return 0
    }
}
