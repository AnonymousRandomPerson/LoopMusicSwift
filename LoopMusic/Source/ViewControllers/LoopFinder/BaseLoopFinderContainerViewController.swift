import UIKit

/// View controller for a container view inside the loop finder.
class BaseLoopFinderContainerViewController<Item>: UIViewController {
    
    /// Parent loop finder view.
    var loopFinder: LoopFinderViewController!
    
    /// Potential items for the track found by the loop finding algorithm.
    var items: [Item] = []
    /// Current item being used.
    var currentItem: Item!
    /// Index of the currently selected item.
    var currentItemIndex: Int = 0
    /// Flag for whether or not to include the original item at the front of the items array.
    var itemsArrayStartsWithOriginal: Bool {
        return false
    }
    /// Flag for viewing manually entered values.
    var manualMode: Bool = false
    
    /// Button to choose the previous item
    @IBOutlet weak var prevButton: UIButton!
    /// Button to choose the next item.
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateRaw()
        if itemsArrayStartsWithOriginal {
            items = [currentItem]
        }
    }
    
    /// Scrolls to the previous item.
    @IBAction func choosePrevItem() {
        chooseItem(at: currentItemIndex - 1)
    }
    
    /// Scrolls to the next item.
    @IBAction func chooseNextItem() {
        chooseItem(at: currentItemIndex + 1)
    }

    /// Scrolls to an item at a specific index
    func chooseItem(at index: Int) {
        if index >= 0 && index < items.count {
            currentItemIndex = index
            updateAutomatic()
        }
    }
    
    /// Updates the current item by whatever's in the music player.
    private func updateRaw() {
        resetCurrentItem()
        enableScrollButtons()
        displayItem()
    }
    
    /// Updates the current item by manual entry, without using loop finding algorithm results.
    func updateManual() {
        manualMode = true
        updateRaw()
    }

    /// Resets the current item to the values currently in the music player.
    func resetCurrentItem() {
    }
    
    /// Updates the item when chosen from the loop finding algorithm results.
    func updateAutomatic() {
        manualMode = false
        updateWithItem(item: items[currentItemIndex])
    }

    /// Does the necessary updates when setting a given item.
    private func updateWithItem(item: Item) {
        currentItem = item
        enableScrollButtons()
        displayItem()
        chooseItem()
    }
    
    /// Updates the parent loop finder with the new item choice.
    func chooseItem() {
    }
    
    /// Displays the current item on the view labels.
    func displayItem() {
    }
    
    /// Enables the next/previous buttons based on scroll position and mode.
    func enableScrollButtons() {
        prevButton.isEnabled = !manualMode && currentItemIndex > 0
        nextButton.isEnabled = !manualMode && currentItemIndex < items.count - 1
    }
    
    /// Changes to a new set of items.
    /// - parameter newItems: The new set of items to use.
    func useNewItems(newItems: [Item]) {
        currentItemIndex = itemsArrayStartsWithOriginal ? 1 : 0
        items = items[..<currentItemIndex] + newItems
        updateAutomatic()
    }
}
