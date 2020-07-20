import UIKit

/// View controller for the loop duration container view inside the loop finder.
class LoopDurationViewController: BaseLoopFinderContainerViewController<LoopDuration> {
    
    /// Label displaying the current duration.
    @IBOutlet weak var durationLabel: UILabel!
    /// Label displaying the current duration's rank.
    @IBOutlet weak var rankLabel: UILabel!
    /// Label displaying the current duration's confidence.
    @IBOutlet weak var confidenceLabel: UILabel!
    /// The minimum allowable item index. -1 for the original loop.
    override var minItemIndex: Int {
        return -1
    }
    
    override func chooseItem() {
        loopFinder.changeLoopDuration(loopDuration: currentItem)
    }
    
    override func resetCurrentItem() {
        currentItem = LoopDuration(rank: nil, confidence: nil, duration: MusicPlayer.player.loopEnd - MusicPlayer.player.loopStart, endpoints: [LoopEndpoints(rank: nil, start: MusicPlayer.player.loopStart, end: MusicPlayer.player.loopEnd)])
    }
    
    /// Displays the current loop duration on the view labels.
    override func displayItem() {
        durationLabel.text = String(format: "Duration: %@", NumberUtils.formatNumber(MusicPlayer.player.convertSamplesToSeconds(currentItem.duration)))
        let defaultRank = manualMode ? "Manual Loop" : "Original Loop"
        rankLabel.text = String(format: "Rank: %@", currentItem.rank == nil ? defaultRank : String(currentItem.rank!))
        confidenceLabel.text = String(format: "Confidence: %@", currentItem.confidence == nil ? "---" : NumberUtils.formatNumber(currentItem.confidence!))
    }
}
