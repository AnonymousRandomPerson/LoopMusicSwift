import UIKit

/// Base view controller for settings section screens.
class BaseSettingsSectionViewController: UITableViewController, UITextFieldDelegate, Unloadable, UIAdaptivePresentationControllerDelegate {
    
    /// Set to true if a setting has changed; the settings file will be saved after seguing back to the settings home.
    var changed: Bool = false
    /// Maps unique hash values of setting views to their respective objects.
    private var settingViews: Dictionary<Int, BaseSettingView> = Dictionary<Int, BaseSettingView>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(BaseSettingsSectionViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        unload(destination: segue.destination)
        segue.destination.presentationController?.delegate = self
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        (presentationController.presentedViewController as? Unloadable)?.unload(destination: self)
        reloadView()
    }
    
    /// Marks the screen as unwindable for segues.
    /// - parameter segue: Segue object performing the segue.
    @IBAction func unwind(segue: UIStoryboardSegue) {
        reloadView()
    }
    
    func reloadView() {
        if let index: IndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: false)
        }
    }
    
    func unload(destination: UIViewController) {
        if changed {
            do {
                try MusicSettings.settings.saveSettingsFile()
            } catch {
                AlertUtils.showErrorMessage(error: error, viewController: self)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    /// Registers a setting view to the internal setting view map.
    /// - parameter settingView: The setting view to add.
    func registerSetting(settingView: BaseSettingView) {
        settingViews[settingView.hashValue()] = settingView
        settingView.displaySetting()
    }
    
    /// Updates a setting when changed in the view.
    /// - parameter sender: The setting view that changed.
    @IBAction func settingChanged(sender: AnyObject) {
        settingViews[ObjectIdentifier(sender).hashValue]?.updateSetting()
        changed = true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
