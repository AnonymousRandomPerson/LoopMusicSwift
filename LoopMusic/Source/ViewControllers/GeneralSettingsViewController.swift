import UIKit

/// View controller for the general settings section.
class GeneralSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch controlling the play-on-init setting.
    @IBOutlet weak var playOnInitSwitch: UISwitch!
    /// Slider controlling the master volume setting.
    @IBOutlet weak var masterVolumeSlider: UISlider!
    /// Slider controlling the default relative volume setting.
    @IBOutlet weak var defaultRelativeVolumeSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        playOnInitSwitch.isOn = MusicSettings.settings.playOnInit
        masterVolumeSlider.value = Float(MusicSettings.settings.masterVolume)
        defaultRelativeVolumeSlider.value = Float(MusicSettings.settings.defaultRelativeVolume)
    }
    
    /// Updates the play-on-init setting when switched on or off.
    @IBAction func playOnInitChanged() {
        MusicSettings.settings.playOnInit = playOnInitSwitch.isOn
        setChanged()
    }
    
    /// Updates the master volume setting.
    @IBAction func masterVolumeChanged() {
        MusicSettings.settings.masterVolume = Double(masterVolumeSlider.value)
        MusicPlayer.player.updateVolume()
        setChanged()
    }
    
    /// Updates the default relative volume setting.
    @IBAction func defaultRelativeVolumeChanged() {
        MusicSettings.settings.defaultRelativeVolume = Double(defaultRelativeVolumeSlider.value)
        setChanged()
    }
}
