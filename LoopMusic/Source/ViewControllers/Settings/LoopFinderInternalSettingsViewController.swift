import UIKit

/// View controller for the loop finder internal settings section.
class LoopFinderInternalSettingsViewController: BaseSettingsSectionViewController {
    
    /// Text field for minimum search duration.
    @IBOutlet weak var minimumSearchDurationField: UITextField!
    /// Text field for duration search separation.
    @IBOutlet weak var durationSearchSeparationField: UITextField!
    /// Text field for duration search start ignore.
    @IBOutlet weak var durationSearchStartIgnoreField: UITextField!
    /// Text field for duration search end ignore.
    @IBOutlet weak var durationSearchEndIgnoreField: UITextField!
    /// Switch for fade detection.
    @IBOutlet weak var fadeDetectionSwitch: UISwitch!
    /// Text field for endpoint search difference tolerance.
    @IBOutlet weak var endpointSearchDifferenceToleranceField: UITextField!
    /// Text field for FFT length.
    @IBOutlet weak var fftLengthField: UITextField!
    /// Text field for spectrogram overlap percentage.
    @IBOutlet weak var spectrogramOverlapPercentageField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.minimumSearchDuration, settingModifier: minimumSearchDurationField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.durationSearchSeparation, settingModifier: durationSearchSeparationField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.durationSearchStartIgnore, settingModifier: durationSearchStartIgnoreField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.durationSearchEndIgnore, settingModifier: durationSearchEndIgnoreField))
        registerSetting(settingView: BooleanSettingView(setting: &MusicSettings.settings.fadeDetection, settingModifier: fadeDetectionSwitch))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.endpointSearchDifferenceTolerance, settingModifier: endpointSearchDifferenceToleranceField))
        registerSetting(settingView: IntSettingView(setting: &MusicSettings.settings.fftLength, settingModifier: fftLengthField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.spectrogramOverlapPercentage, settingModifier: spectrogramOverlapPercentageField))
    }
}
