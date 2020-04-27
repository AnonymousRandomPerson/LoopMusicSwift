import MediaPlayer
import UIKit

/// Controller for the track selection screen.
class TrackListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    /// Table displaying the track list.
    @IBOutlet weak var table: UITableView?
    
    /// Segue identifier for choosing a track.
    private var SEGUE_CHOOSE_TRACK: String = "chooseTrack"
    
    /// Tracks to display. Represents all tracks in the current playlist.
    private var tracks: [MPMediaItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tracks = MediaPlayerUtils.getTracksInPlaylist()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Table cell to modify.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = tracks[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: SEGUE_CHOOSE_TRACK, sender: tracks[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_CHOOSE_TRACK {
            guard let destination = segue.destination as? MusicPlayerViewController else {
                return
            }
            if let selectedTrack: MPMediaItem = sender as? MPMediaItem {
                destination.chooseTrack(mediaItem: selectedTrack)
            }
        }
    }
}
