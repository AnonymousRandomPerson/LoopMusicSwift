import UIKit

/// View controller for the time shuffle settings section.
class TimeShuffleSettingsViewController: BaseSettingsSectionViewController {
    
    /// Text field for shuffle time.
    @IBOutlet weak var shuffleTimeField: UITextField!
    /// Text field for shuffle time variance.
    @IBOutlet weak var shuffleTimeVarianceField: UITextField!
    /// Text field for min shuffle repeats.
    @IBOutlet weak var minShuffleRepeatsField: UITextField!
    /// Text field for max shuffle repeats.
    @IBOutlet weak var maxShuffleRepeatsField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.shuffleTime, settingModifier: shuffleTimeField))
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.shuffleTimeVariance, settingModifier: shuffleTimeVarianceField))
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.minShuffleRepeats, settingModifier: minShuffleRepeatsField))
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.maxShuffleRepeats, settingModifier: maxShuffleRepeatsField))
    }
}
