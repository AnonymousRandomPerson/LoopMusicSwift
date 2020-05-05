import MediaPlayer
import UIKit

/// Controller for the track selection screen.
class PlaylistListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    /// Table displaying the playlist list.
    @IBOutlet weak var table: UITableView?
    
    /// Segue identifier for choosing a playlist.
    private var SEGUE_CHOOSE_PLAYLIST: String = "choosePlaylist"
    
    /// Playlists to display. Represents all playlists in the media library.
    private var playlists: [MPMediaPlaylist] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        playlists = MediaPlayerUtils.getPlaylists()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Table cell to modify.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = playlists[indexPath.row].name
        if playlists[indexPath.row].name == MusicSettings.settings.currentPlaylist.name {
            cell.backgroundColor = UIColor.lightGray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MusicSettings.settings.currentPlaylist = playlists[indexPath.row]
    }
}
