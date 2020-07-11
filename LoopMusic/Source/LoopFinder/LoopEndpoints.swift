import Foundation

/// A set of loop endpoints for a duration.
struct LoopEndpoints {
    
    /// Ranking according to algorithm confidence.
    let rank: Int?
    
    /// Loop start time in samples.
    let start: Int
    
    /// Loop end time in samples.
    let end: Int
}
