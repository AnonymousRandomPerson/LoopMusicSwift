import MediaPlayer
import UIKit

/// View controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController, LoopScrubberContainer, UIAdaptivePresentationControllerDelegate {
    
    /// Notification for updating the track name and scrubber when the current track changes.
    static let NOTIFICATION_CHANGE_TRACK: NSNotification.Name = NSNotification.Name("changeTrack")
    
    /// Button for playing or stopping music playback.
    @IBOutlet weak var playButton: UIButton!
    /// Button for choosing a track to play.
    @IBOutlet weak var tracksButton: UIButton!
    /// Displays the current track name.
    @IBOutlet weak var trackLabel: UILabel!
    /// Button for navigating to the loop finder.
    @IBOutlet weak var loopFinderButton: UIButton!
    
    /// Slider used for playback scrubbing.
    @IBOutlet weak var loopScrubber: LoopScrubber!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrackChange), name: .changeTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruptAudio(notification:)),
                                               name: AVAudioSession.interruptionNotification, object: nil)
        
        do {
            try MusicPlayer.player.initialize()
            try MusicSettings.settings.loadSettingsFile()
            try MusicData.data.openConnection()
        } catch {
           showErrorMessage(error: error)
        }
        
        if (MusicSettings.settings.playOnInit) {
            randomizeTrack()
        }
        updateOnPlay()
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if MusicPlayer.player.playing {
                try MusicPlayer.player.stopTrack()
            } else {
                try MusicPlayer.player.playTrack()
            }
            updateOnPlay()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    /// Plays a random track from the current playlist.
    @IBAction func randomizeTrack() {
        do {
            try MusicPlayer.player.randomizeTrack()
            updateOnPlay()
        } catch {
            showErrorMessage(error: error)
        }
    }
    
    /// Sets the audio playback position using the scrubber.
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
    }
    
    /// Updates UI elements when starting or stopping the current track.
    func updateOnPlay() {
        if MusicPlayer.player.playing {
            loopScrubber?.playTrack()
        } else {
            loopScrubber?.stopTrack()
        }

        playButton.setTitle(MusicPlayer.player.playing ? "■" : "▶", for: .normal)
        playButton.isEnabled = MusicPlayer.player.trackLoaded
        
        loopFinderButton.isEnabled = MusicPlayer.player.playing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        loopScrubber.unload()
        MusicPlayer.player.stopShuffleTimer()
        segue.destination.presentationController?.delegate = self
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
        loopScrubber.updateLoopBox()
        if MusicPlayer.player.playing {
            MusicPlayer.player.startShuffleTimer()
        }
    }
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    func showErrorMessage(error: Error) {
        AlertUtils.showErrorMessage(error: error, viewController: self)
    }

    /// Updates the track label and scrubber according to the currently playing track.
    @objc func updateTrackChange() {
        trackLabel?.text = MusicPlayer.player.currentTrack.name
        loopScrubber?.updateLoopBox()
    }

    /// Handles audio interruptions from events like phone calls or alarms.
    /// - parameter notification: Object with notification metadata.
    @objc func interruptAudio(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let notificationType = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch notificationType {
        case .began:
            do {
                try MusicPlayer.player.interruptTrack()
            } catch {
               showErrorMessage(error: error)
            }
        case .ended:
            do {
                try MusicPlayer.player.resumeTrack()
            } catch {
               showErrorMessage(error: error)
            }
        default: ()
        }
    }
    
    /// Starts playing the chosen track.
    /// - parameter track: Track to play.
    func chooseTrack(track: MPMediaItem) {
        do {
            try MusicPlayer.player.loadTrack(mediaItem: track)
            try MusicPlayer.player.playTrack()
            updateOnPlay()
        } catch {
           showErrorMessage(error: error)
        }
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
}
