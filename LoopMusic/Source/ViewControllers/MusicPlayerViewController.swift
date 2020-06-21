import MediaPlayer
import UIKit

/// View controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController, LoopScrubberContainer {
    
    /// Notification for updating the track name when the current track changes.
    static let NOTIFICATION_TRACK_NAME: NSNotification.Name = NSNotification.Name("trackName")
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrackName(notification:)), name: .trackName, object: nil)
        
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
            self.loopScrubber?.updateLoopBox()
            updateOnPlay()
        } catch {
            showErrorMessage(error: error)
        }
    }
    
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
    }
    
    /// Updates UI elements when starting or stopping the current track.
    func updateOnPlay() {
        if MusicPlayer.player.playing {
            self.loopScrubber?.playTrack()
        } else {
            self.loopScrubber?.stopTrack()
        }

        playButton.setTitle(MusicPlayer.player.playing ? "■" : "▶", for: .normal)
        playButton.isEnabled = MusicPlayer.player.trackLoaded
        
        loopFinderButton.isEnabled = MusicPlayer.player.playing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.loopScrubber.unload()
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
        self.loopScrubber.resume()
    }
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    func showErrorMessage(error: Error) {
        ErrorUtils.showErrorMessage(error: error, viewController: self)
    }

    /// Updates the track label according to the currently playing track.
    /// - parameter notification: Notification triggering the update.
    @objc func updateTrackName(notification: NSNotification) {
        trackLabel?.text = MusicPlayer.player.currentTrack.name
    }
    
    /// Starts playing the chosen track.
    /// - parameter track: Track to play.
    func chooseTrack(track: MPMediaItem) {
        do {
            try MusicPlayer.player.loadTrack(mediaItem: track)
            try MusicPlayer.player.playTrack()
            self.loopScrubber?.updateLoopBox()
            updateOnPlay()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    func getScrubber() -> LoopScrubber {
        return loopScrubber
    }
}
