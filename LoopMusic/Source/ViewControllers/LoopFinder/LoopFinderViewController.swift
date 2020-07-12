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
    
    /// The loop start value upon first entering this screen.
    private var originalLoopStart: Double = 0
    /// The loop end value upon first entering this screen.
    private var originalLoopEnd: Double = 0
    
    /// True if a loop time is changed and should be saved.
    private var loopTimeChanged = false
    /// True if a setting changes and should be saved to the settings file.
    private var settingChanged = false
    
    /// Nested view controller for loop duration selection.
    private var loopDurationView: LoopDurationViewController!
    /// Nested view controller for loop endpoint selection.
    private var loopEndpointsView: LoopEndpointsViewController!
    
    /// Automatic loop finder instance.
    private var loopFinder: LoopFinder = LoopFinder()

    override func viewDidLoad() {
        super.viewDidLoad()
        loopScrubber?.playTrack()
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
        loopStartField.text = NumberUtils.formatNumber(loopStartSeconds)
        MusicPlayer.player.loopStartSeconds = loopStartSeconds
        updateManualLoopTimes()
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
        loopEndField.text = NumberUtils.formatNumber(loopEndSeconds)
        MusicPlayer.player.loopEndSeconds = loopEndSeconds
        updateManualLoopTimes()
    }
    
    /// Sets the loop start time to the current playback time.
    @IBAction func setCurrentStartTime() {
        MusicPlayer.player.loopStartSeconds = MusicPlayer.player.playbackTimeSeconds
        updateManualLoopTimes()
    }
    
    /// Sets the loop end time to the current playback time.
    @IBAction func setCurrentEndTime() {
        MusicPlayer.player.loopEndSeconds = MusicPlayer.player.playbackTimeSeconds
        updateManualLoopTimes()
    }
    
    /// Reverts the loop points to their values when first entering this screen.
    @IBAction func revertLoopPoints() {
        AlertUtils.showConfirmMessage(message: "Revert loop times to their original values?", viewController: self, confirmAction: { _ in
            MusicPlayer.player.loopStartSeconds = self.originalLoopStart
            MusicPlayer.player.loopEndSeconds = self.originalLoopEnd
            self.updateManualLoopTimes()
        })
    }
    
    /// Sets the playback time to shortly before the loop point.
    @IBAction func testLoop() {
        /// The time (seconds) that playback will be set to when testing the loop.
        let testLoopSeconds = MusicPlayer.player.loopEndSeconds - MusicSettings.settings.loopTestOffset
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
    
    /// Finds loop points for the current track automatically.
    @IBAction func searchForLoops() {
        /// The loop durations found by the loop finding algorithm.
        let loopDurations: [LoopDuration] = loopFinder.findLoopPoints()
        if loopDurations.count > 0 {
            loopDurationView.useNewItems(newItems: loopDurations)
        } else {
            AlertUtils.showErrorMessage(error: "Couldn't find suitable loop points.", viewController: self)
        }
    }
    
    /// Changes the loop duration when selected from loop finding results.
    /// - parameter loopDuration: The loop duration to switch to.
    func changeLoopDuration(loopDuration: LoopDuration) {
        loopEndpointsView.durationRank = loopDuration.rank
        loopEndpointsView.useNewItems(newItems: loopDuration.endpoints)
    }
    
    /// Changes the loop endpoints when selected from loop finding results.
    /// - parameter loopEndpoints: The loop endpoints to switch to.
    func changeLoopEndpoints(loopEndpoints: LoopEndpoints) {
        MusicPlayer.player.loopStart = loopEndpoints.start
        MusicPlayer.player.loopEnd = loopEndpoints.end
        updateLoopTimes()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination: LoopDurationViewController = segue.destination as? LoopDurationViewController {
            loopDurationView = destination
            destination.loopFinder = self
        } else if let destination: LoopEndpointsViewController = segue.destination as? LoopEndpointsViewController {
            loopEndpointsView = destination
            destination.loopFinder = self
        } else {
            unload(destination: segue.destination)
            segue.destination.presentationController?.delegate = self
        }
    }
    
    func unload(destination: UIViewController) {
        loopFinder.destroy()
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
    func reloadView() {
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
    
    /// Displays the loop start/end on the corresponding text fields.
    private func displayLoopTimes() {
        loopStartField.text = NumberUtils.formatNumber(MusicPlayer.player.loopStartSeconds)
        loopEndField.text = NumberUtils.formatNumber(MusicPlayer.player.loopEndSeconds)
        loopScrubber.updateLoopBox()
    }
    
    /// Displays the configured loop times and tests automatically if enabled.
    private func updateLoopTimes() {
        displayLoopTimes()
        if MusicSettings.settings.testLoopOnChange {
            testLoop()
        }
        loopTimeChanged = true
    }
    
    /// Updates the current loop duration times, without using loop finding algorithm results.
    private func updateManualLoopTimes() {
        updateLoopTimes()
        loopDurationView.updateManual()
        loopEndpointsView.updateManual()
    }
}
