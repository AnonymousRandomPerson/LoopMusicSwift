import MediaPlayer
import UIKit

/// Controller for the track selection screen.
class TrackListViewController: BaseListViewController<MPMediaItem> {
    
    /// Title label at the top of the screen.
    @IBOutlet weak var titleLabel: UINavigationItem!
    
    /// Segue identifier for choosing a track.
    private var SEGUE_CHOOSE_TRACK: String = "chooseTrack"

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.title = MusicSettings.settings.currentPlaylist.name
    }
    
    override func getItems() -> [MPMediaItem] {
        return MediaPlayerUtils.getTracksInPlaylist()
    }
    
    override func getItemName(_ item: MPMediaItem) -> String {
        return item.title ?? ""
    }

    override func selectItem(_ item: MPMediaItem) {
        self.performSegue(withIdentifier: SEGUE_CHOOSE_TRACK, sender: item)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_CHOOSE_TRACK {
            guard let destination = segue.destination as? MusicPlayerViewController else {
                return
            }
            if let selectedTrack: MPMediaItem = sender as? MPMediaItem {
                destination.chooseTrack(track: selectedTrack)
            }
        }
    }
}
