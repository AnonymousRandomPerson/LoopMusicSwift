import UIKit

/// View controller for the shuffle settings section.
class ShuffleSettingsViewController: BaseSettingsSectionViewController {
    
    /// Switch controlling the shuffle setting.
    @IBOutlet weak var shuffleSettingControl: UISegmentedControl!
    /// Text field for shuffle time.
    @IBOutlet weak var shuffleTimeField: UITextField!
    /// Text field for shuffle repeats.
    @IBOutlet weak var shuffleRepeatsField: UITextField!
    /// Text field for shuffle time variance.
    @IBOutlet weak var shuffleTimeVarianceField: UITextField!
    /// Text field for shuffle repeats variance.
    @IBOutlet weak var shuffleRepeatsVarianceField: UITextField!
    /// Text field for min shuffle time.
    @IBOutlet weak var minShuffleTimeField: UITextField!
    /// Text field for min shuffle repeats.
    @IBOutlet weak var minShuffleRepeatsField: UITextField!
    /// Text field for max shuffle time.
    @IBOutlet weak var maxShuffleTimeField: UITextField!
    /// Text field for max shuffle repeats.
    @IBOutlet weak var maxShuffleRepeatsField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        shuffleSettingControl.selectedSegmentIndex = ShuffleSetting.allCases.firstIndex(of: MusicSettings.settings.shuffleSetting) ?? 0
        shuffleTimeField.text = convertToString(MusicSettings.settings.shuffleTime)
        shuffleRepeatsField.text = convertToString(MusicSettings.settings.shuffleRepeats)
        shuffleTimeVarianceField.text = convertToString(MusicSettings.settings.shuffleTimeVariance)
        shuffleRepeatsVarianceField.text = convertToString(MusicSettings.settings.shuffleRepeatsVariance)
        minShuffleTimeField.text = convertToString(MusicSettings.settings.minShuffleTime)
        minShuffleRepeatsField.text = convertToString(MusicSettings.settings.minShuffleRepeats)
        maxShuffleTimeField.text = convertToString(MusicSettings.settings.maxShuffleTime)
        maxShuffleRepeatsField.text = convertToString(MusicSettings.settings.maxShuffleRepeats)
    }
    
    /// Updates the play-on-init setting when switched on or off.
    @IBAction func shuffleSettingChanged() {
        MusicSettings.settings.shuffleSetting = ShuffleSetting.allCases[shuffleSettingControl.selectedSegmentIndex]
        if MusicSettings.settings.shuffleSetting == ShuffleSetting.none {
            MusicPlayer.player.stopShuffleTimer()
        } else if MusicPlayer.player.playing {
            MusicPlayer.player.startShuffleTimer()
        }
        tableView.reloadData()
        setChanged()
    }
    
    /// Updates the shuffle time setting.
    @IBAction func shuffleTimeChanged() {
        MusicSettings.settings.shuffleTime = parseNumberFromTextField(shuffleTimeField)
        setChanged()
    }
    
    /// Updates the shuffle repeats setting.
    @IBAction func shuffleRepeatsChanged() {
        MusicSettings.settings.shuffleRepeats = parseNumberFromTextField(shuffleRepeatsField)
        setChanged()
    }
    
    /// Updates the shuffle time variance setting.
    @IBAction func shuffleTimeVarianceChanged() {
        MusicSettings.settings.shuffleTimeVariance = parseNumberFromTextField(shuffleTimeVarianceField)
        setChanged()
    }
    
    /// Updates the shuffle repeats variance setting.
    @IBAction func shuffleRepeatsVarianceChanged() {
        MusicSettings.settings.shuffleRepeatsVariance = parseNumberFromTextField(shuffleRepeatsVarianceField)
        setChanged()
    }
    
    /// Updates the min shuffle time setting.
    @IBAction func minShuffleTimeChanged() {
        MusicSettings.settings.minShuffleTime = parseNumberFromTextField(minShuffleTimeField)
        setChanged()
    }
    
    /// Updates the min shuffle repeats setting.
    @IBAction func minShuffleRepeatsChanged() {
        MusicSettings.settings.minShuffleRepeats = parseNumberFromTextField(minShuffleRepeatsField)
        setChanged()
    }
    
    /// Updates the max shuffle time setting.
    @IBAction func maxShuffleTimeChanged() {
        MusicSettings.settings.maxShuffleTime = parseNumberFromTextField(maxShuffleTimeField)
        setChanged()
    }
    
    /// Updates the max shuffle repeats setting.
    @IBAction func maxShuffleRepeatsChanged() {
        MusicSettings.settings.maxShuffleRepeats = parseNumberFromTextField(maxShuffleRepeatsField)
        setChanged()
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            switch MusicSettings.settings.shuffleSetting {
            case ShuffleSetting.none: return "No automatic track shuffling."
            case ShuffleSetting.time: return "Shuffle tracks after an amount of time (seconds) has passed."
            case ShuffleSetting.repeats: return "Shuffle tracks after the track repeats (loops) a number of times."
            }
        }
        return super.tableView(tableView, titleForFooterInSection: section)
    }
}
