import MediaPlayer
import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController, MPMediaPickerControllerDelegate {
    
    static let NOTIFICATION_TRACK_NAME: NSNotification.Name = NSNotification.Name("trackName")
    
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var tracksButton: UIButton?
    @IBOutlet weak var trackLabel: UILabel?
    
    let musicPlayer: MusicPlayer = MusicPlayer()

    /// Do any additional setup after loading the view.
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
    func handleMessageError(error: MessageError) {
        showErrorMessage(message: "Error: " + error.message)
    }
    
    /// Displays an NSError to the user.
    func handleNSError(error: NSError) {
        showErrorMessage(message: "Error: " + error.code.description)
    }
    
    /// Displays an error to the user.
    func showErrorMessage(message: String) {
        print(message)
    }
    
    /// Selects an audio track to play.
    @IBAction func chooseTracks(_ sender: UIButton) {
        let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
        myMediaPickerVC.popoverPresentationController?.sourceView = sender
        myMediaPickerVC.delegate = self
        self.present(myMediaPickerVC, animated: true, completion: nil)
    }
    
    /// Plays the track selected from the media picker.
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        if mediaItemCollection.count > 0 {
            do {
                try musicPlayer.loadTrack(mediaItem: mediaItemCollection.items[0])
                try musicPlayer.playTrack()
            } catch let error as MessageError {
                handleMessageError(error: error)
            } catch let error as NSError {
                handleNSError(error: error)
            }
        }
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    /// Dismisses the music player without selecting a track.
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }

    /// Updates the track label according to the currently playing track.
    @objc func updateTrackName(notification: NSNotification) {
        trackLabel?.text = musicPlayer.currentTrack.name
    }
}
