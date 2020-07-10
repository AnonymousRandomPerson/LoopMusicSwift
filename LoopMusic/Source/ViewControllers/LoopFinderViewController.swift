import UIKit

/// View controller for the loop finder.
class LoopFinderViewController: UIViewController, LoopScrubberContainer, UITextFieldDelegate, Unloadable, UIAdaptivePresentationControllerDelegate {
    
    /// Text field used to edit the loop start.
    @IBOutlet weak var loopStartField: UITextField!
    
    /// Text field used to edit the loop end.
    @IBOutlet weak var loopEndField: UITextField!
    
    /// Slider used for playback scrubbing.
    @IBOutlet weak var loopScrubber: LoopScrubber!
    
    /// Switch for initial estimate.
    @IBOutlet weak var initialEstimateSwitch: UISwitch!
    
    /// Formatter for displaying loop times.
    private var loopTimeFormat: NumberFormatter!
    
    /// The loop start value upon first entering this screen.
    private var originalLoopStart: Double = 0
    /// The loop end value upon first entering this screen.
    private var originalLoopEnd: Double = 0
    
    /// True if a loop time is changed and should be saved.
    private var loopTimeChanged = false
    /// True if a setting changes and should be saved to the settings file.
    private var settingChanged = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loopScrubber?.playTrack()
        
        loopTimeFormat = NumberFormatter()
        loopTimeFormat.minimumFractionDigits = 0
        loopTimeFormat.maximumFractionDigits = 4
        displayLoopTimes()
        
        originalLoopStart = MusicPlayer.player.loopStartSeconds
        originalLoopEnd = MusicPlayer.player.loopEndSeconds
        
        initialEstimateSwitch.isOn = MusicSettings.settings.initialEstimate
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(LoopFinderViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    /// Sets the loop start time when the loop start text field is edited.
    @IBAction func changeLoopStartField() {
        /// Number of seconds to set the loop start to.
        var loopStartSeconds: Double
        if let text = loopStartField.text, let loopStart = Double(text) {
            loopStartSeconds = min(max(loopStart, 0), MusicPlayer.player.loopEndSeconds)
        } else {
            loopStartSeconds = 0
        }
        MusicPlayer.player.loopStartSeconds = loopStartSeconds
        updateLoopTimes()
    }
    
    /// Sets the loop end time when the loop end text field is edited.
    @IBAction func changeLoopEndField() {
        /// Number of seconds to set the loop end to.
        var loopEndSeconds: Double
        if let text = loopEndField.text, let loopEnd = Double(text) {
            loopEndSeconds = min(max(loopEnd, MusicPlayer.player.loopStartSeconds), MusicPlayer.player.durationSeconds)
        } else {
            loopEndSeconds = MusicPlayer.player.durationSeconds
        }
        MusicPlayer.player.loopEndSeconds = loopEndSeconds
        updateLoopTimes()
    }
    
    /// Sets the loop start time to the current playback time.
    @IBAction func setCurrentStartTime() {
        MusicPlayer.player.loopStartSeconds = MusicPlayer.player.playbackTimeSeconds
        updateLoopTimes()
    }
    
    /// Sets the loop end time to the current playback time.
    @IBAction func setCurrentEndTime() {
        MusicPlayer.player.loopEndSeconds = MusicPlayer.player.playbackTimeSeconds
        updateLoopTimes()
    }
    
    /// Reverts the loop points to their values when first entering this screen.
    @IBAction func revertLoopPoints() {
        AlertUtils.showConfirmMessage(message: "Revert loop times to their original values?", viewController: self, confirmAction: { _ in
            MusicPlayer.player.loopStartSeconds = self.originalLoopStart
            MusicPlayer.player.loopEndSeconds = self.originalLoopEnd
            self.updateLoopTimes()
        })
    }
    
    /// Sets the playback time to shortly before the loop point.
    @IBAction func testLoop() {
        /// The time (seconds) that playback will be set to when testing the loop.
        let testLoopSeconds = MusicPlayer.player.loopEndSeconds - (MusicSettings.settings.loopTestOffset ?? 0)
        MusicPlayer.player.playbackTimeSeconds = max(0, testLoopSeconds)
    }
    
    /// Sets the audio playback position using the scrubber.
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
    }
    
    /// Changes the initial estimate setting when the switch is flipped.
    @IBAction func setInitialEstimate() {
        MusicSettings.settings.initialEstimate = initialEstimateSwitch.isOn
        settingChanged = true
    }
    
    /// Toggles whether loop playback is enabled.
    /// - parameter uiSwitch: Switch controlling loop playback.
    @IBAction func toggleLoopPlayback(uiSwitch: UISwitch) {
        MusicPlayer.player.updateLoopPlayback(loopPlayback: uiSwitch.isOn)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        unload(destination: segue.destination)
        segue.destination.presentationController?.delegate = self
    }
    
    func unload(destination: UIViewController) {
        loopScrubber.unload()
        if destination is MusicPlayerViewController {
            MusicPlayer.player.updateLoopPlayback(loopPlayback: true)
            
            if loopTimeChanged {
                do {
                    try MusicPlayer.player.saveLoopPoints()
                } catch {
                    AlertUtils.showErrorMessage(error: error, viewController: self)
                }
            }
            
            if settingChanged {
                do {
                    try MusicSettings.settings.saveSettingsFile()
                } catch {
                    AlertUtils.showErrorMessage(error: error, viewController: self)
                }
            }
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        (presentationController.presentedViewController as? Unloadable)?.unload(destination: self)
        reloadView()
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
        reloadView()
    }
    
    /// Restarts paused elements in the view after a presented view is dismissed.
    private func reloadView() {
        loopScrubber.resume()
    }
    
    func getScrubber() -> LoopScrubber {
        return loopScrubber
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            self.loopScrubber.updateLoopBox()
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// Displays the configured loop times and tests automatically if enabled.
    private func updateLoopTimes() {
        displayLoopTimes()
        if MusicSettings.settings.testLoopOnChange {
            testLoop()
        }
        loopTimeChanged = true
    }
    
    /// Displays the loop start/end on the corresponding text fields.
    private func displayLoopTimes() {
        loopStartField.text = loopTimeFormat.string(from: NSNumber(value: MusicPlayer.player.loopStartSeconds))
        loopEndField.text = loopTimeFormat.string(from: NSNumber(value: MusicPlayer.player.loopEndSeconds))
        loopScrubber.updateLoopBox()
    }
}
