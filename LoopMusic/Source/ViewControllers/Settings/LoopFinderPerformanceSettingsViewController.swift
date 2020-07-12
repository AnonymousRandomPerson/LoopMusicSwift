import UIKit

/// View controller for the loop finder performance settings section.
class LoopFinderPerformanceSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch for using mono audio.
    @IBOutlet weak var useMonoAudioSwitch: UISwitch!
    /// Text field for frame rate reduction.
    @IBOutlet weak var frameRateReductionField: UITextField!
    /// Text field for frame rate reduction limit.
    @IBOutlet weak var frameRateReductionLimitField: UITextField!
    /// Text field for track length limit.
    @IBOutlet weak var trackLengthLimitField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: BooleanSettingView(setting: &MusicSettings.settings.useMonoAudio, settingModifier: useMonoAudioSwitch))
        registerSetting(settingView: IntSettingView(setting: &MusicSettings.settings.frameRateReduction, settingModifier: frameRateReductionField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.frameRateReductionLimit, settingModifier: frameRateReductionLimitField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.trackLengthLimit, settingModifier: trackLengthLimitField))
    }
}
