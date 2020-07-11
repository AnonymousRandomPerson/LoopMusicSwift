import UIKit

/// View controller for the loop endpoints container view inside the loop finder.
class LoopEndpointsViewController: BaseLoopFinderContainerViewController<LoopEndpoints> {
    
    /// Label displaying the current endpoint set's rank.
    @IBOutlet weak var rankLabel: UILabel!
    /// The rank of the duration containing the current endpoints.
    var durationRank: Int?
    
    override func chooseItem() {
        loopFinder.changeLoopEndpoints(loopEndpoints: currentItem)
    }
    
    override func resetCurrentItem() {
        currentItem = LoopEndpoints(rank: nil, start: MusicPlayer.player.loopStart, end: MusicPlayer.player.loopEnd)
    }
    
    /// Displays the current loop duration on the view labels.
    override func displayItem() {
        rankLabel.text = String(format: "Rank: %@", currentItem.rank == nil ? "---" : String(format: "%i.%i", durationRank ?? 0, currentItem.rank!))
    }
}
