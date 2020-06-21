import MediaPlayer
import UIKit

/// Base view controller for list views.
class BaseListViewController<Item>: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    /// Table displaying the item list.
    @IBOutlet public weak var table: UITableView!
    /// Search bar for searching items.
    @IBOutlet public weak var itemSearchBar: UISearchBar!
    
    /// All items in the list.
    private var items: [Item] = []
    /// Items to display based on search, or all items if there's no search value.
    var filteredItems: [Item] = []
    /// Name of the subclass. Used to index the searchValues dictionary.
    private var className: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        items = getItems()
        filteredItems = items;
        className = String(describing: type(of: self))
        if let savedSearchValue: String = SearchValueStore.searchValues[className] {
            itemSearchBar.text = savedSearchValue
            filterItems(savedSearchValue)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Table cell to modify.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = getItemName(filteredItems[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectItem(filteredItems[indexPath.row])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            searchBarCancelButtonClicked(searchBar)
        } else {
            filterItems(searchText)
            SearchValueStore.searchValues[className] = searchText
            table.reloadData()
        }
    }
    
    func filterItems(_ searchText: String) {
        filteredItems = items.filter({ getItemName($0).localizedCaseInsensitiveContains(searchText) })
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredItems = items
        SearchValueStore.searchValues[className] = nil
        table.reloadData()
    }
    
    /// Gets all items in the list.
    /// - returns: List of items in the list.
    func getItems() -> [Item] {
        return []
    }
    
    /// Gets the name of an item. Used for item display and searching.
    /// - parameter item: Item to get a name for.
    /// - returns: Item name.
    func getItemName(_ item: Item) -> String {
        return ""
    }

    /// Handles selecting a table item.
    /// - parameter item: Selected item.
    func selectItem(_ item: Item) {
    }
}

/// Saved search values to restore them when the user revisits the corresponding screen. Class name -> search value.
class SearchValueStore {
    
    static var searchValues: [String: String] = [:]
}
