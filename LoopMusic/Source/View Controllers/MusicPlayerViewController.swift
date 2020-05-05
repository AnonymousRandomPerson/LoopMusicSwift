import MediaPlayer
import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController {
    
    /// Notification for updating the track name when the current track changes.
    static let NOTIFICATION_TRACK_NAME: NSNotification.Name = NSNotification.Name("trackName")
    
    /// Button for playing or stopping music playback.
    @IBOutlet weak var playButton: UIButton?
    /// Button for choosing a track to play.
    @IBOutlet weak var tracksButton: UIButton?
    /// Displays the current track name.
    @IBOutlet weak var trackLabel: UILabel?
    
    /// Handles music loading and playback.
    let musicPlayer: MusicPlayer = MusicPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrackName(notification:)), name: .trackName, object: nil)
        
        MusicSettings.settings.loadSettingsFile()
        
        do {
            try MusicData.data.openConnection()
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
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
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
        }
    }
    
    /// Plays a random track from the current playlist.
    @IBAction func randomizeTrack() {
        do {
            try musicPlayer.randomizeTrack()
            updatePlayButtonIcon()
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
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
    
    /// Displays a MessageError to the user.
    /// - parameter error: Error to display.
    func handleMessageError(error: MessageError) {
        showErrorMessage(message: "Error: " + error.message)
    }
    
    /// Displays an NSError to the user.
    /// - parameter error: Error to display.
    func handleNSError(error: NSError) {
        showErrorMessage(message: "Error: " + error.code.description)
    }
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    func showErrorMessage(message: String) {
        print(message)
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
        }
    }
}
