import UIKit

/// View controller for the loop finder initial estimate settings section.
class LoopFinderInitialEstimateSettingsViewController: BaseSettingsSectionViewController {
    
    /// Text field for start time estimate radius.
    @IBOutlet weak var startTimeEstimateRadiusField: UITextField!
    /// Text field for end time estimate radius.
    @IBOutlet weak var endTimeEstimateRadiusField: UITextField!
    /// Text field for loop duration estimate radius.
    @IBOutlet weak var loopDurationEstimateRadiusField: UITextField!
    /// Slider for start time estimate penalty.
    @IBOutlet weak var startTimeEstimateDeviationPenaltySlider: UISlider!
    /// Slider for end time estimate penalty.
    @IBOutlet weak var endTimeEstimateDeviationPenaltySlider: UISlider!
    /// Slider for loop duration estimate deviation penalty.
    @IBOutlet weak var loopDurationEstimateDeviationPenaltySlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.startTimeEstimateRadius, settingModifier: startTimeEstimateRadiusField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.endTimeEstimateRadius, settingModifier: endTimeEstimateRadiusField))
        registerSetting(settingView: DoubleTextFieldSettingView(setting: &MusicSettings.settings.loopDurationEstimateRadius, settingModifier: loopDurationEstimateRadiusField))
        registerSetting(settingView: DoubleSliderSettingView(setting: &MusicSettings.settings.startTimeEstimateDeviationPenalty, settingModifier: startTimeEstimateDeviationPenaltySlider))
        registerSetting(settingView: DoubleSliderSettingView(setting: &MusicSettings.settings.endTimeEstimateDeviationPenalty, settingModifier: endTimeEstimateDeviationPenaltySlider))
        registerSetting(settingView: DoubleSliderSettingView(setting: &MusicSettings.settings.loopDurationEstimateDeviationPenalty, settingModifier: loopDurationEstimateDeviationPenaltySlider))
    }
}
