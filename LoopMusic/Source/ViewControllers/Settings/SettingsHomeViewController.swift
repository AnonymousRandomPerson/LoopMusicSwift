import UIKit

/// View controller for the top-level settings screen.
class SettingsHomeViewController: UITableViewController, UIAdaptivePresentationControllerDelegate {
    
    /// Cell used to navigate to track settings.
    @IBOutlet weak var trackSettingsCell: UITableViewCell!
    /// Label in the track settings cell.
    @IBOutlet weak var trackSettingsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trackSettingsCell.isUserInteractionEnabled = MusicPlayer.player.trackLoaded
        trackSettingsLabel.isEnabled = MusicPlayer.player.trackLoaded
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.presentationController?.delegate = self
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        (presentationController.presentedViewController as? Unloadable)?.unload(destination: self)
        reloadView()
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
        reloadView()
    }
    
    func reloadView() {
        if let index: IndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: false)
        }
    }
}
