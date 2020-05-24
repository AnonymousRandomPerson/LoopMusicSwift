import UIKit

/// Setting view for a boolean value controlled by a switch.
class BooleanSettingView: BaseSettingViewGeneric<Bool, UISwitch> {
    
    override func displaySetting() {
        settingModifier.isOn = setting.pointee
    }
    
    override func fetchSettingFromModifier() -> Bool {
        return settingModifier.isOn
    }
}
