import MediaPlayer
import UIKit

/// View controller for the music player (home screen) of the app.
class MusicPlayerViewController: UIViewController, LoopScrubberContainer, UIAdaptivePresentationControllerDelegate {
    
    /// Notification for updating the track name and scrubber when the current track changes.
    static let NOTIFICATION_CHANGE_TRACK: NSNotification.Name = NSNotification.Name("changeTrack")

    /// Notification for updating the playlist button when the current playlist changes.
    static let NOTIFICATION_CHANGE_PLAYLIST: NSNotification.Name = NSNotification.Name("changePlaylist")
    
    /// Button for playing or stopping music playback.
    @IBOutlet weak var playButton: UIButton!
    /// Button for choosing a track to play.
    @IBOutlet weak var tracksButton: ColorBackedButton!
    /// Button for choosing a playlist.
    @IBOutlet weak var playlistsButton: ColorBackedButton!
    /// Displays the current track name.
    @IBOutlet weak var trackLabel: UILabel!
    /// Button for opening settings.
    @IBOutlet weak var settingsButton: ColorBackedButton!
    /// Button for navigating to the loop finder.
    @IBOutlet weak var loopFinderButton: ColorBackedButton!
    
    /// Slider used for playback scrubbing.
    @IBOutlet weak var loopScrubber: LoopScrubber!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrackChange), name: .changeTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaylistChange), name: .changePlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruptAudio(notification:)),
                                               name: AVAudioSession.interruptionNotification, object: nil)
        
        playlistsButton.titleLabel?.numberOfLines = 3
        // Round only some corners of the buttons. Note: only works in iOS 11+
        tracksButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        playlistsButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        settingsButton.layer.maskedCorners = [.layerMaxXMinYCorner]
        loopFinderButton.layer.maskedCorners = [.layerMinXMinYCorner]

        do {
            try MusicPlayer.player.initialize()
            try MusicSettings.settings.loadSettingsFile()
            try MusicData.data.openConnection()
        } catch {
           showErrorMessage(error: error)
        }

        if (MusicSettings.settings.playOnInit) {
            randomizeTrack()
        }
        updateOnPlay()
    }
    
    /// Toggles whether audio is playing.
    @IBAction func toggleAudio() {
        do {
            if MusicPlayer.player.playing {
                try MusicPlayer.player.pauseTrack(interrupted: false)
            } else {
                try MusicPlayer.player.playTrack()
            }
            updateOnPlay()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    /// If the playback time is before a certain threshold and there are previous tracks in recent memory, play the previous track. Otherwise, reset playback.
    @IBAction func rewind() {
        do {
            try MusicPlayer.player.rewind()
            updateOnPlay()
        } catch {
            showErrorMessage(error: error)
        }
    }

    /// Plays the next track, or a random one if there is no next track.
    @IBAction func nextTrack() {
        do {
            try MusicPlayer.player.loadNextTrack()
            updateOnPlay()
        } catch {
            showErrorMessage(error: error)
        }
    }

    /// Plays a random track from the current playlist.
    @IBAction func randomizeTrack() {
        do {
            try MusicPlayer.player.randomizeTrack()
            updateOnPlay()
        } catch {
            showErrorMessage(error: error)
        }
    }
    
    /// Sets the audio playback position using the scrubber.
    @IBAction func setPlaybackPosition() {
        loopScrubber.setPlaybackPosition()
    }
    
    /// Updates UI elements when starting, pausing, or stopping the current track.
    func updateOnPlay() {
        if MusicPlayer.player.trackLoaded {
            loopScrubber?.updateValue() // Make sure the scrubber value is up to date
        }
        if MusicPlayer.player.playing {
            loopScrubber?.playTrack()
        } else if MusicPlayer.player.paused {
            loopScrubber?.pauseTrack()
        } else {
            loopScrubber?.stopTrack()
        }

        // \u{f04c} = pause, \u{f04b} = play
        // Using Font Awesome 5 Free: https://fontawesome.com/license/free
        playButton.setTitle(MusicPlayer.player.playing ? "\u{f04c}" : "\u{f04b}", for: .normal)
        playButton.isEnabled = MusicPlayer.player.trackLoaded
        
        loopFinderButton.isEnabled = MusicPlayer.player.playing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        loopScrubber.unload()
        MusicPlayer.player.stopShuffleTimer()
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
    
    /// Restarts paused elements in the view after a presented view is dismissed.
    private func reloadView() {
        loopScrubber.resume()
        loopScrubber.updateLoopBox()
        if MusicPlayer.player.playing {
            MusicPlayer.player.startShuffleTimer()
        }
    }
    
    /// Displays an error to the user.
    /// - parameter message: Error message to display.
    func showErrorMessage(error: Error) {
        AlertUtils.showErrorMessage(error: error, viewController: self)
    }

    /// Updates the track label and scrubber according to the currently playing track.
    @objc func updateTrackChange() {
        trackLabel?.text = MusicPlayer.player.currentTrack.name
        loopScrubber?.updateLoopBox()
    }

    /// Updates the playlist label according to the current playlist.
    @objc func updatePlaylistChange() {
        if let attributedTitle = playlistsButton?.attributedTitle(for: .normal) {
            let header = "Current Playlist:\n"
            let playlistName = MusicSettings.settings.currentPlaylist.name ?? ""
            let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
            mutableAttributedTitle.replaceCharacters(in: NSRange(location: 0, length: mutableAttributedTitle.length), with: header + playlistName)
            // Make the playlist name bold.
            let font = mutableAttributedTitle.attributes(at: 0, effectiveRange: nil)[.font] as! UIFont
            mutableAttributedTitle.addAttribute(.font, value: FontUtils.boldFont(font), range: NSRange(location: header.count, length: playlistName.count))
            playlistsButton.setAttributedTitle(mutableAttributedTitle, for: .normal)
        }
        playlistsButton.layoutIfNeeded()    // Change immediately without animation.
    }

    /// Handles audio interruptions from events like phone calls or alarms.
    /// - parameter notification: Object with notification metadata.
    @objc func interruptAudio(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let notificationType = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch notificationType {
        case .began:
            do {
                try MusicPlayer.player.pauseTrack(interrupted: true)
            } catch {
               showErrorMessage(error: error)
            }
        case .ended:
            if MusicPlayer.player.interrupted {
                do {
                    try MusicPlayer.player.playTrack()
                } catch {
                   showErrorMessage(error: error)
                }
            }
        default: ()
        }
        updateOnPlay()
    }
    
    /// Starts playing the chosen track.
    /// - parameter track: Track to play.
    func chooseTrack(track: MPMediaItem) {
        do {
            try MusicPlayer.player.loadTrack(mediaItem: track)
            try MusicPlayer.player.playTrack()
            updateOnPlay()
        } catch {
           showErrorMessage(error: error)
        }
    }
    
    func getScrubber() -> LoopScrubber {
        return loopScrubber
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            self.loopScrubber.updateLoopBox()
        })
    }
}
