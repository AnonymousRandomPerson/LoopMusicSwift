import UIKit

/// Utility functions for showing alerts.
class AlertUtils {
    
    /// Displays an error to the user.
    /// - parameter error: Error to display.
    /// - parameter viewController: View to show the dialog in.
    static func showErrorMessage(error: Error, viewController: UIViewController) {
        print(error)
        showErrorMessage(error: error.localizedDescription, viewController: viewController)
    }
    
    /// Displays an error to the user.
    /// - parameter error: Error to display.
    /// - parameter viewController: View to show the dialog in.
    static func showErrorMessage(error: String, viewController: UIViewController) {
        print(error)
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    /// Displays a confirmation dialog to the user.
    /// - parameter message: Confirmation message to display.
    /// - parameter viewController: View to show the dialog in.
    /// - parameter confirmAction: Action to invoke if the user confirms the action.
    static func showConfirmMessage(message: String, viewController: UIViewController, confirmAction: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: "Confirm", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: confirmAction))
        viewController.present(alert, animated: true, completion: nil)
    }
}
