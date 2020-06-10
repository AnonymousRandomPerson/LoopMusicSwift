import UIKit

/// Scrubber for controlling playback position.
class LoopScrubber: UISlider {

    /// The amount of time (seconds) between each slider position update.
    static let PLAYBACK_TIMER_INTERVAL: Double = 0.2
    
    /// Timer used to update the slider position as audio playback progresses.
    private var playbackTimer: Timer?
    
    /// Renders the rectangle marking the looped portion of the track.
    private var loopBox: UIView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.loopBox == nil {
            self.loopBox = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.bounds.height))
            self.loopBox?.isUserInteractionEnabled = false
            self.loopBox?.layer.cornerRadius = 3
            self.loopBox?.backgroundColor = UIColor.green.withAlphaComponent(0.25)
            self.insertSubview(self.loopBox!, belowSubview: self.subviews.last!)
        }
    }
    
    /// Starts the slider update loop when a track starts.
    func playTrack() {
        self.startTimer()
        self.isEnabled = true
    }
    
    /// Starts the slider update loop.
    func startTimer() {
        if self.playbackTimer == nil {
            self.playbackTimer = Timer.scheduledTimer(withTimeInterval: LoopScrubber.self.PLAYBACK_TIMER_INTERVAL, repeats: true) { timer in
                self.value = Float(MusicPlayer.player.sampleCounter) / Float(MusicPlayer.player.numSamples)
            }
        }
    }
    
    /// Updates the position of the loop box according to the current track.
    func changeTrack() {
        self.loopBox?.frame = CGRect(
            x: CGFloat(Float(MusicPlayer.player.loopStart) / Float(MusicPlayer.player.numSamples)) * self.bounds.width,
            y: 0,
            width: CGFloat(Float(MusicPlayer.player.loopEnd - MusicPlayer.player.loopStart) / Float(MusicPlayer.player.numSamples)) * self.bounds.width,
            height: self.bounds.height)
        self.loopBox?.backgroundColor = UIColor.green.withAlphaComponent(0.25)
    }
    
    func setPlaybackPosition() {
        MusicPlayer.player.sampleCounter = Int(self.value * Float(MusicPlayer.player.numSamples))
    }
    
    /// Disables the scrubber when playback stops.
    func stopTrack() {
        self.unload()
        self.value = 0
        self.isEnabled = false
    }
    
    /// Invalidates the playback timer before unloading the view.
    func unload() {
        print("Paused")
        self.playbackTimer?.invalidate()
        self.playbackTimer = nil
    }
    
    /// Starts the update timer again after resuming the app.
    func resume() {
        print("Resumed")
        if self.isEnabled {
            self.startTimer()
        }
    }
}
