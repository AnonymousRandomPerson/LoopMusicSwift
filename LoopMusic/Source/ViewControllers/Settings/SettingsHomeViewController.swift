import UIKit

/// View controller for the top-level settings screen.
class SettingsHomeViewController: UITableViewController {
    
    /// Cell used to navigate to track settings.
    @IBOutlet weak var trackSettingsCell: UITableViewCell!
    /// Label in the track settings cell.
    @IBOutlet weak var trackSettingsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trackSettingsCell.isUserInteractionEnabled = MusicPlayer.player.trackLoaded
        trackSettingsLabel.isEnabled = MusicPlayer.player.trackLoaded
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }
}
