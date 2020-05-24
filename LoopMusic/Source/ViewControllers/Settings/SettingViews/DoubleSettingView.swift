import UIKit

/// Setting view for a decimal value controlled by a slider.
class DoubleSliderSettingView: BaseSettingViewGeneric<Double, UISlider> {
    
    override func displaySetting() {
        settingModifier.value = Float(setting.pointee)
    }
    
    override func fetchSettingFromModifier() -> Double {
        return Double(settingModifier.value)
    }
}
