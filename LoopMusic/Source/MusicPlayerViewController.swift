import UIKit

/// Controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController {
    
    let musicPlayer: MusicPlayer = MusicPlayer()

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try musicPlayer.loadTrack(trackId: "")
        } catch let error as MessageError {
            print("Error: " + error.message);
        } catch let error as NSError {
            print("Error: " + error.code.description);
        }
    }

}
