import UIKit

/// Base view controller for settings section screens.
class BaseSettingsSectionViewController: UITableViewController {
    
    /// Set to true if a setting has changed; the settings file will be saved after seguing back to the settings home.
    private var changed: Bool = false
    
    /// Marks settings as changed to save them upon seguing.
    func setChanged() {
        changed = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if changed {
            if let _ = segue.destination as? SettingsHomeViewController {
                do {
                    try MusicSettings.settings.saveSettingsFile()
                } catch {
                    ErrorUtils.showErrorMessage(error: error, viewController: self)
                }
            }
        }
    }
}
