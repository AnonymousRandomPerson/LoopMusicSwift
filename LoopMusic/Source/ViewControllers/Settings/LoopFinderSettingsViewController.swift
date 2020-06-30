import UIKit

/// View controller for the loop finder settings screen.
class LoopFinderSettingsViewController: BaseSettingsSectionViewController {
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }
    
    /// Resets loop finder settings to their default values.
    @IBAction func resetLoopFinderSettings() {
        AlertUtils.showConfirmMessage(message: "Reset all loop finder settings to their default values?", viewController: self, confirmAction: { _ in
            MusicSettings.settings.resetLoopFinderSettings()
            self.changed = true
        })
    }
}
