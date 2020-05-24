import UIKit

/// Setting view for shuffle setting, controlled by a segmented control.
class ShuffleSettingView: BaseSettingViewGeneric<ShuffleSetting, UISegmentedControl> {
    
    override func displaySetting() {
        settingModifier.selectedSegmentIndex = ShuffleSetting.allCases.firstIndex(of: setting.pointee) ?? 0
    }
    
    override func fetchSettingFromModifier() -> ShuffleSetting {
        return ShuffleSetting.allCases[settingModifier.selectedSegmentIndex]
    }
}
