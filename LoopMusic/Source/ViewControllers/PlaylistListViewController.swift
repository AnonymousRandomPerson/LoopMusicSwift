import MediaPlayer
import UIKit

/// Controller for the playlist selection screen.
class PlaylistListViewController: BaseListViewController<MPMediaPlaylist> {
    
    override func getItems() -> [MPMediaPlaylist] {
        return MediaPlayerUtils.getPlaylists()
    }
    
    override func getItemName(_ item: MPMediaPlaylist) -> String {
        return item.name ?? ""
    }

    override func selectItem(_ item: MPMediaPlaylist) {
        MusicSettings.settings.currentPlaylist = item
        do {
            try MusicSettings.settings.saveSettingsFile()
        } catch {
            ErrorUtils.showErrorMessage(error: error, viewController: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = super.tableView(tableView, cellForRowAt: indexPath)
        if filteredItems[indexPath.row].name == MusicSettings.settings.currentPlaylist.name {
            cell.backgroundColor = UIColor.lightGray
        }
        return cell
    }
}
