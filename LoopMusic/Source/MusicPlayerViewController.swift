import MediaPlayer
import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController, MPMediaPickerControllerDelegate {
    
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var tracksButton: UIButton?
    @IBOutlet weak var trackLabel: UILabel?
    
    let musicPlayer: MusicPlayer = MusicPlayer()

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try MusicData.data.openConnection()
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
        }
        trackLabel?.text = musicPlayer.currentTrack.name
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if musicPlayer.playing {
                try musicPlayer.stopTrack()
                playButton?.setTitle("▶", for: .normal)
            } else {
                try musicPlayer.playTrack()
                playButton?.setTitle("■", for: .normal)
            }
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
        }
    }
    
    @IBAction func randomizeTrack() {
        do {
            try musicPlayer.randomizeTrack()
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
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
    
    /// Select an audio track to play.
    @IBAction func chooseTracks(_ sender: UIButton) {
        let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
        myMediaPickerVC.popoverPresentationController?.sourceView = sender
        myMediaPickerVC.delegate = self
        self.present(myMediaPickerVC, animated: true, completion: nil)
    }
    
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

    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }

}
