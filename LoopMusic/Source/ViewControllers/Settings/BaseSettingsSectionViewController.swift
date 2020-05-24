import UIKit

/// Base view controller for settings section screens.
class BaseSettingsSectionViewController: UITableViewController, UITextFieldDelegate {
    
    /// Set to true if a setting has changed; the settings file will be saved after seguing back to the settings home.
    private var changed: Bool = false
    private var settingViews: Dictionary<Int, BaseSettingView> = Dictionary<Int, BaseSettingView>()
    
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
    
    func registerSetting(settingView: BaseSettingView) {
        settingViews[settingView.hashValue()] = settingView
        settingView.displaySetting()
    }
    
    /// Updates the play-on-init setting when switched on or off.
    @IBAction func settingChanged(sender: AnyObject) {
        settingViews[ObjectIdentifier(sender).hashValue]?.updateSetting()
        setChanged()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
