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
        // Never reduce the framerate by more than a factor of 4. For a standard 44.1 kHz signal, a factor of 4 reduction gives an effective framerate of 11.025 kHz, with a corresponding Nyquist frequency of 5.5125 kHz. Since the human ear is most sensitive to frequencies between 2 kHz and 5 kHz, reducing any further would seriously degrade the quality of the loudness calculation, which is designed to weight frequencies in a way that reflects human perception.
        let framerateReductionLimit: Int = min(4, Int(round(MusicSettings.settings.frameRateReductionLimit)))
        let lengthLimit: Int = Int(MusicSettings.settings.trackLengthLimit)
        var intrinsicLoudness: Double = 0
        if (calcIntegratedLoudnessFromBufferFormat(&audioData, framerateReductionLimit, lengthLimit, &intrinsicLoudness) < 0) {
            AlertUtils.showErrorMessage(error: "Failed to calculate integrated loudness.", viewController: self)
            return
        }

        if let normalizationLevel = MusicSettings.settings.volumeNormalizationLevel {
            // Try to shift the average volume to the desired level by setting the relative volume multiplier.
            // The shift must be nonpositive since we can't raise the volume higher than the intrinsic volume.
            let dbShift = min(0, normalizationLevel - intrinsicLoudness)
            let relativeVolume = pow(10, dbShift/20)
            relativeVolumeSlider.value = Float(relativeVolume)
            relativeVolumeChanged(sender: relativeVolumeSlider)
        } else {
            // If no normalization level was specified, set it so that the relative volume multiplier would remain unchanged. But don't let the level go below the minimum; a minimum isn't strictly necessary, and dB can in theory go down to -infinity if the volume multiplier is 0, but it would be a bad interface to fill the text box with huge negative values for very low multipliers.
            let normalizationLevel = max(Double(DB_REFERENCE_LUFS), intrinsicLoudness + 20*log10(MusicPlayer.player.volumeMultiplier))
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
