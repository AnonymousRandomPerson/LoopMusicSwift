import MediaPlayer
import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController {
    
    /// Notification for updating the track name when the current track changes.
    static let NOTIFICATION_TRACK_NAME: NSNotification.Name = NSNotification.Name("trackName")
    
    /// Button for playing or stopping music playback.
    @IBOutlet weak var playButton: UIButton!
    /// Button for choosing a track to play.
    @IBOutlet weak var tracksButton: UIButton!
    /// Displays the current track name.
    @IBOutlet weak var trackLabel: UILabel!
    
    /// Handles music loading and playback.
    let musicPlayer: MusicPlayer = MusicPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrackName(notification:)), name: .trackName, object: nil)
        
        
        do {
            try MusicSettings.settings.loadSettingsFile()
            try MusicData.data.openConnection()
        } catch {
           showErrorMessage(error: error)
        }
        
        if (MusicSettings.settings.playOnInit) {
            randomizeTrack()
        }
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if musicPlayer.playing {
                try musicPlayer.stopTrack()
            } else {
                try musicPlayer.playTrack()
            }
            updatePlayButtonIcon()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    /// Plays a random track from the current playlist.
    @IBAction func randomizeTrack() {
        do {
            try musicPlayer.randomizeTrack()
            updatePlayButtonIcon()
        } catch {
            showErrorMessage(error: error)
        }
    }
    
    /// Sets the play button icon depending on whether music is playing.
    func updatePlayButtonIcon() {
        if musicPlayer.playing {
            playButton?.setTitle("■", for: .normal)
        } else {
            playButton?.setTitle("▶", for: .normal)
        }
    }
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    func showErrorMessage(error: Error) {
        ErrorUtils.showErrorMessage(error: error, viewController: self)
    }

    /// Updates the track label according to the currently playing track.
    /// - parameter notification: Notification triggering the update.
    @objc func updateTrackName(notification: NSNotification) {
        trackLabel?.text = musicPlayer.currentTrack.name
    }
    
    /// Marks the music player screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwindToMusicPlayer(segue: UIStoryboardSegue) {
    }
    
    /// Starts playing the chosen track.
    /// - parameter track: Track to play.
    func chooseTrack(track: MPMediaItem) {
        do {
            try musicPlayer.loadTrack(mediaItem: track)
            try musicPlayer.playTrack()
            updatePlayButtonIcon()
        } catch {
           showErrorMessage(error: error)
        }
    }
}
