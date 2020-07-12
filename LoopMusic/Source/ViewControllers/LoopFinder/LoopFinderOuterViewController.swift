import UIKit

/// Container view with the scroll view for the loop finder.
class LoopFinderOuterViewController: UIViewController, Unloadable {
    
    /// Inner loop finder view.
    var loopFinderView: LoopFinderViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination: LoopFinderViewController = segue.destination as? LoopFinderViewController {
            loopFinderView = destination
        }
    }
    
    func unload(destination: UIViewController) {
        loopFinderView.unload(destination: destination)
    }
}
