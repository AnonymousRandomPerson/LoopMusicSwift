import UIKit

/// View controller for the top-level settings screen.
class SettingsHomeViewController: UITableViewController {
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwindToSettingsHome(segue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let _ = segue.destination as? MusicPlayerViewController {
            do {
                try MusicSettings.settings.saveSettingsFile()
            } catch {
                ErrorUtils.showErrorMessage(error: error, viewController: self)
            }
        }
    }
}
