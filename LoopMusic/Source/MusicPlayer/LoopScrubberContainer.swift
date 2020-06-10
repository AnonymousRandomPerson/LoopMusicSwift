/// Marks a view controller that contains a loop scrubber. Used for pausing the update timer when the app enters the background.
protocol LoopScrubberContainer {
    
    /// Gets the loop scrubber object in the view controller.
    /// - returns: The loop scrubber object in the view controller.
    func getScrubber() -> LoopScrubber
}
