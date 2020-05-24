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
        
        self.registerSetting(settingView: BooleanSettingView(setting: &MusicSettings.settings.playOnInit, settingModifier: playOnInitSwitch))
        self.registerSetting(settingView: DoubleSliderSettingView(setting: &MusicSettings.settings.masterVolume, settingModifier: masterVolumeSlider))
        self.registerSetting(settingView: DoubleSliderSettingView(setting: &MusicSettings.settings.defaultRelativeVolume, settingModifier: defaultRelativeVolumeSlider))
    }
    
    /// Updates the master volume setting.
    @IBAction func masterVolumeChanged(sender: UISlider) {
        super.settingChanged(sender: sender)
        MusicPlayer.player.updateVolume()
    }
}
