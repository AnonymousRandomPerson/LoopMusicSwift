import UIKit

/// Setting view for a decimal value controlled by a slider.
class DoubleTextFieldSettingView: BaseSettingViewGeneric<Double?, UITextField> {
    
    override func displaySetting() {
        if let number = setting.pointee {
            let format = NumberFormatter()
            format.minimumFractionDigits = 0
            format.maximumFractionDigits = 4
            settingModifier.text = format.string(from: NSNumber(value: number))
        }
    }
    
    override func fetchSettingFromModifier() -> Double? {
        if let text = settingModifier.text, let number = Double(text) {
            return number
        }
        return nil
    }
}
