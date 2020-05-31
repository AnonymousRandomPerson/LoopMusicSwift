import UIKit

/// View controller for the repeats shuffle settings section.
class RepeatsShuffleSettingsViewController: BaseSettingsSectionViewController {
    
    /// Text field for shuffle repeats.
    @IBOutlet weak var shuffleRepeatsField: UITextField!
    /// Text field for shuffle repeats variance.
    @IBOutlet weak var shuffleRepeatsVarianceField: UITextField!
    /// Text field for min shuffle time.
    @IBOutlet weak var minShuffleTimeField: UITextField!
    /// Text field for max shuffle time.
    @IBOutlet weak var maxShuffleTimeField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleRepeats, settingModifier: shuffleRepeatsField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.shuffleRepeatsVariance, settingModifier: shuffleRepeatsVarianceField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.minShuffleTime, settingModifier: minShuffleTimeField))
        self.registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.maxShuffleTime, settingModifier: maxShuffleTimeField))
    }
}
