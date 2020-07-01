import UIKit

/// View controller for the loop finder.
class LoopFinderViewController: UIViewController, LoopScrubberContainer, UITextFieldDelegate {
    
    /// Text field used to edit the loop start.
    @IBOutlet weak var loopStartField: UITextField!
    
    /// Text field used to edit the loop end.
    @IBOutlet weak var loopEndField: UITextField!
    
    /// Slider used for playback scrubbing.
    @IBOutlet weak var loopScrubber: LoopScrubber!
    
    /// Formatter for displaying loop times.
    private var loopTimeFormat: NumberFormatter!
    
    /// The loop start value upon first entering this screen.
    private var originalLoopStart: Double = 0
    /// The loop end value upon first entering this screen.
    private var originalLoopEnd: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loopScrubber?.playTrack()
        
        loopTimeFormat = NumberFormatter()
        loopTimeFormat.minimumFractionDigits = 0
        loopTimeFormat.maximumFractionDigits = 4
        displayLoopTimes()
        
        originalLoopStart = MusicPlayer.player.loopStartSeconds
        originalLoopEnd = MusicPlayer.player.loopEndSeconds
        
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
        // Multiply sample rate by 2 to account for two channels.
        MusicPlayer.player.sampleCounter = max(0, Int(testLoopSeconds * Double(MusicPlayer.player.sampleRate * 2)))
    }
    
    /// Sets the audio playback position using the scrubber.
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.loopScrubber.unload()
        if segue.destination is MusicPlayerViewController {
            do {
                try MusicPlayer.player.saveLoopPoints()
            } catch {
                AlertUtils.showErrorMessage(error: error, viewController: self)
            }
        }
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
        self.loopScrubber.resume()
    }
    
    func getScrubber() -> LoopScrubber {
        return loopScrubber
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
    }
    
    /// Displays the loop start/end on the corresponding text fields.
    private func displayLoopTimes() {
        loopStartField.text = loopTimeFormat.string(from: NSNumber(value: MusicPlayer.player.loopStartSeconds))
        loopEndField.text = loopTimeFormat.string(from: NSNumber(value: MusicPlayer.player.loopEndSeconds))
        loopScrubber.updateLoopBox()
    }
}
