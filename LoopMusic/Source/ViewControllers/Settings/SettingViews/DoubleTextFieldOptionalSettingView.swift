import UIKit

/// Setting view for an optional decimal value controlled by a text field.
class DoubleTextFieldOptionalSettingView: BaseSettingViewGeneric<Double?, UITextField> {
    
    override func displaySetting() {
        if let number = setting.pointee {
            let format = NumberFormatter()
            format.minimumFractionDigits = 0
            format.maximumFractionDigits = 5
            settingModifier.text = NumberUtils.formatNumber(number)
        }
    }
    
    override func fetchSettingFromModifier() -> Double? {
        if let text = settingModifier.text, let number = Double(text) {
            return number
        }
        return nil
    }
}
