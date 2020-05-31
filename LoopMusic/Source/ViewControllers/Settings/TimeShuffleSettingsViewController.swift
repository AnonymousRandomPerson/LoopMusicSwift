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
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleTime, settingModifier: shuffleTimeField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleTimeVariance, settingModifier: shuffleTimeVarianceField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.minShuffleRepeats, settingModifier: minShuffleRepeatsField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.maxShuffleRepeats, settingModifier: maxShuffleRepeatsField))
    }
}
