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
    
    /// Button to choose the previous item
    @IBOutlet weak var prevButton: UIButton!
    /// Button to choose the next item.
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateManual()
        items = [currentItem]
        enableScrollButtons()
    }
    
    /// Scrolls to the previous item.
    @IBAction func choosePrevItem() {
        if currentItemIndex > 0 {
            currentItemIndex -= 1
            updateAutomatic()
        }
    }
    
    /// Scrolls to the next item.
    @IBAction func chooseNextItem() {
        if currentItemIndex < items.count - 1 {
            currentItemIndex += 1
            updateAutomatic()
        }
    }
    
    /// Updates the current item manually, without using loop finding algorithm results.
    func updateManual() {
        resetCurrentItem()
        displayItem()
    }
    
    /// Resets the current item to the values currently in the music player.
    func resetCurrentItem() {
    }
    
    /// Updates the item when chosen from the loop finding algorithm results.
    func updateAutomatic() {
        currentItem = items[currentItemIndex]
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
    
    /// Enables the next/previous buttons based on scroll position.
    func enableScrollButtons() {
        prevButton.isEnabled = currentItemIndex > 0
        nextButton.isEnabled = currentItemIndex < items.count - 1
    }
    
    /// Changes to a new set of items.
    /// - parameter newItems: The new set of items to use.
    func useNewItems(newItems: [Item]) {
        items = newItems
        currentItemIndex = 0
        updateAutomatic()
    }
}
