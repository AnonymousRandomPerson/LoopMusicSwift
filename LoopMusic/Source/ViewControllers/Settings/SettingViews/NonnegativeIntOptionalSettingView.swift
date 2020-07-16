import UIKit

/// Setting view for a nonnegative optional integer value (but still of type Int) controlled by a text field.
class NonnegativeIntOptionalSettingView:IntOptionalSettingView {

    override func fetchSettingFromModifier() -> Int? {
        if let text = settingModifier.text, let number = Int(text) {
            return max(0, number)
        }
        return nil
    }
}
