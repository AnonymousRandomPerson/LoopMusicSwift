import Foundation

/// A loop duration time found by the loop finder.
struct LoopDuration {
    
    /// Duration ranking according to algorithm confidence.
    let rank: Int?
    
    /// Confidence percentage of the duration.
    let confidence: Double?
    
    /// Duration of the loop in samples.
    let duration: Int
    
    /// Potential endpoints for the duration.
    let endpoints: [LoopEndpoints]
}
