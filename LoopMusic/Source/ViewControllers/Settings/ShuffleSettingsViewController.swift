import UIKit

/// View controller for the shuffle settings section.
class ShuffleSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch controlling the shuffle setting.
    @IBOutlet weak var shuffleSettingControl: UISegmentedControl!
    /// Text field for fade duration.
    @IBOutlet weak var fadeDurationField: UITextField!
    /// Text field for shuffle history length.
    @IBOutlet weak var shuffleHistoryLengthField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: ShuffleSettingView(setting: &MusicSettings.settings.shuffleSetting, settingModifier: shuffleSettingControl))
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.fadeDuration, settingModifier: fadeDurationField))
        registerSetting(settingView: NonnegativeIntOptionalSettingView(setting: &MusicSettings.settings.shuffleHistoryLength, settingModifier: shuffleHistoryLengthField))
    }

    /// Prunes the track history queue based on the new history length.
    @IBAction func shuffleHistoryLengthChanged(sender:UITextField) {
        super.settingChanged(sender: sender)
        MusicPlayer.player.pruneTrackHistory()
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
        if section == 2 {
            switch MusicSettings.settings.shuffleSetting {
            case ShuffleSetting.none: return "No automatic track shuffling."
            case ShuffleSetting.time: return "Shuffle tracks after an amount of time (seconds) has passed."
            case ShuffleSetting.repeats: return "Shuffle tracks after the track repeats (loops) a number of times."
            }
        }
        return super.tableView(tableView, titleForFooterInSection: section)
    }
}
