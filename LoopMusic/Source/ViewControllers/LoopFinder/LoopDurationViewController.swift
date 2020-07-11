import UIKit

/// View controller for the loop duration container view inside the loop finder.
class LoopDurationViewController: BaseLoopFinderContainerViewController<LoopDuration> {
    
    /// Label displaying the current duration.
    @IBOutlet weak var durationLabel: UILabel!
    /// Label displaying the current duration's rank.
    @IBOutlet weak var rankLabel: UILabel!
    /// Label displaying the current duration's confidence.
    @IBOutlet weak var confidenceLabel: UILabel!
    
    override func chooseItem() {
        loopFinder.changeLoopDuration(loopDuration: currentItem)
    }
    
    override func resetCurrentItem() {
        currentItem = LoopDuration(rank: nil, confidence: nil, duration: MusicPlayer.player.loopEnd - MusicPlayer.player.loopStart, endpoints: [LoopEndpoints(rank: nil, start: MusicPlayer.player.loopStart, end: MusicPlayer.player.loopEnd)])
    }
    
    /// Displays the current loop duration on the view labels.
    override func displayItem() {
        durationLabel.text = String(format: "Duration: %@", loopFinder.formatLoopTime(MusicPlayer.player.convertSamplesToSeconds(currentItem.duration)))
        rankLabel.text = String(format: "Rank: %@", currentItem.rank == nil ? "---" : String(currentItem.rank!))
        confidenceLabel.text = String(format: "Confidence: %@", currentItem.confidence == nil ? "---" : loopFinder.formatLoopTime(currentItem.confidence!))
    }
}
