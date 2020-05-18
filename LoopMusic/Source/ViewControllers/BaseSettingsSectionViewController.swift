import UIKit

/// Base view controller for settings section screens.
class BaseSettingsSectionViewController: UITableViewController, UITextFieldDelegate {
    
    /// Set to true if a setting has changed; the settings file will be saved after seguing back to the settings home.
    private var changed: Bool = false
    
    /// Marks settings as changed to save them upon seguing.
    func setChanged() {
        changed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(BaseSettingsSectionViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if changed {
            if let _ = segue.destination as? SettingsHomeViewController {
                do {
                    try MusicSettings.settings.saveSettingsFile()
                } catch {
                    ErrorUtils.showErrorMessage(error: error, viewController: self)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    /// Parses a number out of a text field.
    /// - parameter textField: Text field with text to parse.
    /// - returns: Optional double if the text field can be parsed to a number.
    func parseNumberFromTextField(_ textField: UITextField) -> Double? {
        if let text = textField.text, let number = Double(text) {
            return number
        }
        return nil
    }
    
    /// Returns a string from an optional double, or nil if the number is nil.
    /// - parameter number: Double to convert to a string.
    /// - returns: Optional string from the optional double.
    func convertToString(_ number: Double?) -> String? {
        if let number = number {
            let format: NumberFormatter = NumberFormatter()
            format.minimumFractionDigits = 0
            format.maximumFractionDigits = 4
            return format.string(from: NSNumber(value: number))
        }
        return nil
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
