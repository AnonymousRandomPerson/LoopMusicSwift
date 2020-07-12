import UIKit

/// View controller for the loop finder output settings section.
class LoopFinderOutputSettingsViewController: BaseSettingsSectionViewController {
    
    /// Text field for duration values.
    @IBOutlet weak var durationValuesField: UITextField!
    /// Text field for endpoint pairs.
    @IBOutlet weak var endpointPairsField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: IntSettingView(setting: &MusicSettings.settings.durationValues, settingModifier: durationValuesField))
        registerSetting(settingView: IntSettingView(setting: &MusicSettings.settings.endpointPairs, settingModifier: endpointPairsField))
    }
}
