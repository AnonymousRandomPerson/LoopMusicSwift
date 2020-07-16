import UIKit

/// Scrubber for controlling playback position.
class LoopScrubber: UISlider {

    /// The amount of time (seconds) between each slider position update.
    static let PLAYBACK_TIMER_INTERVAL: Double = 0.2
    
    /// Timer used to update the slider position as audio playback progresses.
    private var playbackTimer: Timer?
    
    /// Renders the rectangle marking the looped portion of the track.
    private var loopBox: UIView?
    
    /// Width of the thumb image.
    private var thumbWidth: CGFloat = 0
    
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
            if (MusicPlayer.player.trackLoaded) {
                updateLoopBox()
            }
        }
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        /// Thumb image to retrieve the width from.
        let thumbRect: CGRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        thumbWidth = thumbRect.width
        return thumbRect
    }
    
    /// Starts the slider update loop when a track starts.
    func playTrack() {
        self.startTimer()
        self.isEnabled = true
    }
    
    /// Updates the slider value with the current playback time.
    func updateValue() {
        value = Float(MusicPlayer.player.sampleCounter) / Float(MusicPlayer.player.numSamples)
    }

    /// Starts the slider update loop.
    func startTimer() {
        if self.playbackTimer == nil {
            self.playbackTimer = Timer.scheduledTimer(withTimeInterval: LoopScrubber.self.PLAYBACK_TIMER_INTERVAL, repeats: true) { [weak self] _ in self?.updateValue() }
        }
    }
    
    /// Updates the position of the loop box according to the current track.
    func updateLoopBox() {
        if MusicPlayer.player.trackLoaded {
            /// Width of the scrollable area of the slider (excluding the edges past the thumb bounding box).
            let scrollableWidth: CGFloat = self.bounds.width - thumbWidth
            self.loopBox?.frame = CGRect(
                x: CGFloat(Float(MusicPlayer.player.loopStart) / Float(MusicPlayer.player.numSamples)) * scrollableWidth,
                y: 0,
                width: CGFloat(Float(MusicPlayer.player.loopEnd - MusicPlayer.player.loopStart) / Float(MusicPlayer.player.numSamples)) * scrollableWidth + thumbWidth,
                height: self.bounds.height)
            self.loopBox?.backgroundColor = UIColor.green.withAlphaComponent(0.25)
        }
    }
    
    func setPlaybackPosition() {
        MusicPlayer.player.sampleCounter = Int(self.value * Float(MusicPlayer.player.numSamples))
    }
    
    /// Pauses the scrubber when playback is paused.
    func pauseTrack() {
        self.unload()
    }

    /// Disables the scrubber when playback stops.
    func stopTrack() {
        self.unload()
        self.value = 0
    }
    
    /// Invalidates the playback timer before unloading the view.
    func unload() {
        self.playbackTimer?.invalidate()
        self.playbackTimer = nil
    }
    
    /// Starts the update timer again after resuming the app.
    func resume() {
        if self.isEnabled {
            self.startTimer()
        }
    }
}
