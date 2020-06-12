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
        updatePlayButtonIcon()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.loopScrubber.unload()
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if MusicPlayer.player.playing {
                try MusicPlayer.player.stopTrack()
            } else {
                try MusicPlayer.player.playTrack()
            }
            updatePlayButtonIcon()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    /// Plays a random track from the current playlist.
    @IBAction func randomizeTrack() {
        do {
            try MusicPlayer.player.randomizeTrack()
            self.loopScrubber?.changeTrack()
            updatePlayButtonIcon()
        } catch {
            showErrorMessage(error: error)
        }
    }
    
    /// Sets the play button icon depending on whether music is playing.
    func updatePlayButtonIcon() {
        if MusicPlayer.player.playing {
            playButton?.setTitle("■", for: .normal)
            self.loopScrubber?.playTrack()
        } else {
            playButton?.setTitle("▶", for: .normal)
            self.loopScrubber?.stopTrack()
        }
        playButton?.isEnabled = MusicPlayer.player.trackLoaded
    }
    
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
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
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwindToMusicPlayer(segue: UIStoryboardSegue) {
        self.loopScrubber.resume()
    }
    
    /// Starts playing the chosen track.
    /// - parameter track: Track to play.
    func chooseTrack(track: MPMediaItem) {
        do {
            try MusicPlayer.player.loadTrack(mediaItem: track)
            try MusicPlayer.player.playTrack()
            self.loopScrubber?.changeTrack()
            updatePlayButtonIcon()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    func getScrubber() -> LoopScrubber {
        return loopScrubber
    }
}
