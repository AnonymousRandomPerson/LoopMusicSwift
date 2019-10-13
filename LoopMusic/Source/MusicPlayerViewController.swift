import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton?
    
    let musicPlayer: MusicPlayer = MusicPlayer()

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try musicPlayer.loadTrack(trackId: "")
        } catch let error as MessageError {
            handleMessageError(error: error)
        } catch let error as NSError {
            handleNSError(error: error)
        }
    }
    
    /// Select an audio track to play.
    func selectTrack(trackId: String) {
        
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if (musicPlayer.playing) {
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
}
