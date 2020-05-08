import UIKit

/// Utility functions for error handling.
class ErrorUtils {
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    static func showErrorMessage(error: Error, viewController: UIViewController) {
        print(error)
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}
