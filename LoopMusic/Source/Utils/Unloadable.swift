import UIKit

/// A shared function to consolidate multiple ways of unloading a screen.
protocol Unloadable {
    
    /// Unloads the view.
    /// - parameter destination: The view controller being transitioned to.
    func unload(destination: UIViewController)
}
