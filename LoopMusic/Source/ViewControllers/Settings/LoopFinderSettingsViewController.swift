import UIKit

/// View controller for the loop finder settings screen.
class LoopFinderSettingsViewController: BaseSettingsSectionViewController {
    
    /// Resets loop finder settings to their default values.
    @IBAction func resetLoopFinderSettings() {
        AlertUtils.showConfirmMessage(message: "Reset all loop finder settings to their default values?", viewController: self, confirmAction: { _ in
            MusicSettings.settings.resetLoopFinderSettings()
            self.changed = true
        })
    }
}
