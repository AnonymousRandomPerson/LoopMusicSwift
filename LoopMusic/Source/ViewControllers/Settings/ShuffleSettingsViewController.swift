import UIKit

/// View controller for the shuffle settings section.
class ShuffleSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch controlling the shuffle setting.
    @IBOutlet weak var shuffleSettingControl: UISegmentedControl!
    /// Text field for shuffle time.
    @IBOutlet weak var shuffleTimeField: UITextField!
    /// Text field for shuffle repeats.
    @IBOutlet weak var shuffleRepeatsField: UITextField!
    /// Text field for shuffle time variance.
    @IBOutlet weak var shuffleTimeVarianceField: UITextField!
    /// Text field for shuffle repeats variance.
    @IBOutlet weak var shuffleRepeatsVarianceField: UITextField!
    /// Text field for min shuffle time.
    @IBOutlet weak var minShuffleTimeField: UITextField!
    /// Text field for min shuffle repeats.
    @IBOutlet weak var minShuffleRepeatsField: UITextField!
    /// Text field for max shuffle time.
    @IBOutlet weak var maxShuffleTimeField: UITextField!
    /// Text field for max shuffle repeats.
    @IBOutlet weak var maxShuffleRepeatsField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerSetting(settingView: ShuffleSettingView(setting: &MusicSettings.settings.shuffleSetting, settingModifier: shuffleSettingControl))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleTime, settingModifier: shuffleTimeField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleRepeats, settingModifier: shuffleRepeatsField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleTimeVariance, settingModifier: shuffleTimeVarianceField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleRepeatsVariance, settingModifier: shuffleRepeatsVarianceField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.minShuffleTime, settingModifier: minShuffleTimeField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.minShuffleRepeats, settingModifier: minShuffleRepeatsField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.maxShuffleTime, settingModifier: maxShuffleTimeField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.maxShuffleRepeats, settingModifier: maxShuffleRepeatsField))
    }
    
    /// Stops or starts the shuffle timer based on the new shuffle setting.
    @IBAction func shuffleSettingChanged(sender: UISegmentedControl) {
        super.settingChanged(sender: sender)
        if MusicSettings.settings.shuffleSetting == ShuffleSetting.none {
            MusicPlayer.player.stopShuffleTimer()
        } else if MusicPlayer.player.playing {
            MusicPlayer.player.startShuffleTimer()
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            switch MusicSettings.settings.shuffleSetting {
            case ShuffleSetting.none: return "No automatic track shuffling."
            case ShuffleSetting.time: return "Shuffle tracks after an amount of time (seconds) has passed."
            case ShuffleSetting.repeats: return "Shuffle tracks after the track repeats (loops) a number of times."
            }
        }
        return super.tableView(tableView, titleForFooterInSection: section)
    }
}
