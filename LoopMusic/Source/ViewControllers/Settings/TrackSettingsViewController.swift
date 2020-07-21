import UIKit

/// View controller for the track settings section.
class TrackSettingsViewController: BaseSettingsSectionViewController {
        
    /// Slider controlling the relative volume setting.
    @IBOutlet weak var relativeVolumeSlider: UISlider!
    /// Text field for volume normalization level.
    @IBOutlet weak var volumeNormalizationLevelField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        relativeVolumeSlider.value = Float(MusicPlayer.player.volumeMultiplier)
        registerSetting(settingView: DoubleTextFieldOptionalSettingView(setting: &MusicSettings.settings.volumeNormalizationLevel, settingModifier: volumeNormalizationLevelField))
    }
    
    /// Updates the relative volume setting.
    @IBAction func relativeVolumeChanged(sender: UISlider) {
        super.settingChanged(sender: sender)
        MusicPlayer.player.volumeMultiplier = Double(sender.value)
    }
    
    /// Automatically normalizes the relative volume setting.
    @IBAction func normalizeVolume() {
        // Compute the track's intrinsic average volume.
        var audioData = MusicPlayer.player.audioData
        let framerateReductionLimit: Int = Int(round(MusicSettings.settings.frameRateReductionLimit))
        let lengthLimit: Int = Int(MusicSettings.settings.trackLengthLimit)
        let intrinsicVolume = Double(calcAvgVolumeFromBufferFormat(&audioData, framerateReductionLimit, lengthLimit))

        if let text = volumeNormalizationLevelField.text, let normalizationLevel = Double(text) {
            // Try to shift the average volume to the desired level by setting the relative volume multiplier.
            // The shift must be nonpositive since we can't raise the volume higher than the intrinsic volume.
            let dbShift = min(0, normalizationLevel - intrinsicVolume)
            let relativeVolume = pow(10, dbShift/20)
            relativeVolumeSlider.value = Float(relativeVolume)
            relativeVolumeChanged(sender: relativeVolumeSlider)
        } else {
            // If no normalization level was specified, set it so that the relative volume multiplier would remain unchanged. But don't let the level go negative!
            let normalizationLevel = max(0, intrinsicVolume + 20*log10(MusicPlayer.player.volumeMultiplier))
            volumeNormalizationLevelField.text = NumberUtils.formatNumber(normalizationLevel)
            super.settingChanged(sender: volumeNormalizationLevelField)
        }
    }

    override func unload(destination: UIViewController) {
        super.unload(destination: destination)
        if changed {
            do {
                try MusicPlayer.player.saveVolumeMultiplier()
            } catch {
                AlertUtils.showErrorMessage(error: error, viewController: self)
            }
        }
    }
}
