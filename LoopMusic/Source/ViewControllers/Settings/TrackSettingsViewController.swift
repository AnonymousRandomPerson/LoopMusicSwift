import UIKit

/// View controller for the track settings section.
class TrackSettingsViewController: BaseSettingsSectionViewController {
        
    /// Slider controlling the relative volume setting.
    @IBOutlet weak var relativeVolumeSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        relativeVolumeSlider.value = Float(MusicPlayer.player.volumeMultiplier)
    }
    
    /// Updates the relative volume setting.
    @IBAction func relativeVolumeChanged(sender: UISlider) {
        super.settingChanged(sender: sender)
        MusicPlayer.player.volumeMultiplier = Double(sender.value)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if changed {
            do {
                try MusicPlayer.player.saveVolumeMultiplier()
            } catch {
                ErrorUtils.showErrorMessage(error: error, viewController: self)
            }
        }
    }
}
