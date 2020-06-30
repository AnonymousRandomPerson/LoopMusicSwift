import UIKit

/// View controller for the loop finder testing settings section.
class LoopFinderTestingSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch for testing loop on change.
    @IBOutlet weak var testLoopOnChangeSwitch: UISwitch!
    /// Text field for loop test offset.
    @IBOutlet weak var loopTestOffsetField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: BooleanSettingView(setting: &MusicSettings.settings.testLoopOnChange, settingModifier: testLoopOnChangeSwitch))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.loopTestOffset, settingModifier: loopTestOffsetField))
    }
}
