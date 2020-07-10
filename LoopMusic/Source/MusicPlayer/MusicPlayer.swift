import AVFoundation
import CoreAudio
import Foundation
import MediaPlayer

/// Handles playback and looping of music tracks.
class MusicPlayer {
    
    /// The default number of frames to be read from an audio file when loading the initial portion of audio.
    static let START_READ_FRAMES: AVAudioFramePosition = AVAudioFramePosition(1000000)
    /// The number of frames to be read from an audio file each time it is read from asynchronously.
    static let FRAME_READ_INCREMENT: AVAudioFrameCount = AVAudioFrameCount(100000)
    
    /// The amount of time (seconds) between each volume decrement when fading out.
    static let FADE_DECREMENT_TIME: Double = 0.1
    
    /// Singleton instance.
    static let player: MusicPlayer = MusicPlayer()
    
    /// The track currently loaded in the music player.
    private(set) var currentTrack: MusicTrack = MusicTrack.BLANK_MUSIC_TRACK
    /// True if the player is currently playing a track.
    private(set) var playing: Bool = false

    /// Timer used to shuffle tracks after playing for a while.
    private var shuffleTimer: Timer?

    /// Timer used to fade out tracks before shuffling them.
    private var fadeTimer: Timer?
    
    /// Sample rate of the currently loaded track.
    private(set) var sampleRate: Double = 44100
    
    /// Audio data for the currently playing track.
    private var audioBuffer: AudioBuffer?
    /// True if the current audio track was converted manually.
    private var manuallyAllocatedBuffer: Bool = false
    
    /// Lock to prevent the audio buffer from being loaded and freed at the same time.
    private var bufferLock: DispatchSemaphore = DispatchSemaphore(value: 1)
    /// Passed to the dispatch queue tasks so the audio loading task knows if the track changes while it's still loading.
    private var trackUuid: UUID = UUID()
    
    /// Volume multiplier used when fading out.
    private var fadeMultiplier: Double = 1
    
    /// True if the player has a track loaded in it.
    var trackLoaded: Bool {
        get {
            return currentTrack.url != MusicTrack.BLANK_MUSIC_TRACK.url
        }
    }

    /// The index of the currently playing sample within the audio data.
    var sampleCounter: Int {
        get {
            return Int(getSampleCounter())
        }
        set {
            setSampleCounter(Int64(newValue))
        }
    }

    /// The total number of samples in the audio data.
    var numSamples: Int {
        get {
            return Int(getNumSamples());
        }
    }
    
    /// The length of the audio data in seconds.
    var durationSeconds: Double {
        get {
            return Double(numSamples) / sampleRate
        }
    }

    /// The audio sample to start the loop at.
    var loopStart: Int {
        get {
            return Int(getLoopStart());
        }
    }

    /// The audio sample to end the loop at.
    var loopEnd: Int {
        get {
            return Int(getLoopEnd());
        }
    }
    
    /// The number of seconds to start the loop at.
    var loopStartSeconds: Double {
        get {
            return currentTrack.loopStart
        }
        set {
            currentTrack.loopStart = newValue
            updateLoopPoints()
        }
    }
    
    /// The number of seconds to end the loop at.
    var loopEndSeconds: Double {
        get {
            return currentTrack.loopEnd
        }
        set {
            currentTrack.loopEnd = newValue
            updateLoopPoints()
        }
    }
    
    var volumeMultiplier: Double {
        get {
            return currentTrack.volumeMultiplier
        }
        set {
            currentTrack.volumeMultiplier = newValue
            updateVolume()
        }
    }
    
    /// Sets up audio playback.
    func initialize() throws {
        try enableBackgroundAudio()
    }
    
    /// Loads a track into the music player.
    /// - parameter mediaItem: The audio track to play.
    func loadTrack(mediaItem: MPMediaItem) throws {
        try stopTrack()
        
        // Unload the buffer for the previous track.
        bufferLock.wait()
        if let audioBuffer: AudioBuffer = audioBuffer {
            free(audioBuffer.mData)
        }
        trackUuid = UUID()
        bufferLock.signal()
        
        currentTrack = try MusicData.data.loadTrack(mediaItem: mediaItem)
        /// Audio file containing the track to load.
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: currentTrack.url)
        } catch {
            throw MessageError("Failed to read audio file.", error)
        }
        
        /// Initial number of audio frames to read before starting audio playback.
        let startReadFrames: AVAudioFrameCount = AVAudioFrameCount(min(audioFile.length, MusicPlayer.START_READ_FRAMES))
        guard let origBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: startReadFrames) else {
            throw MessageError("Audio is not in PCM format.")
        }
        
        /// Pointer to the audio file's audio description.
        let origAudioDescPointer: UnsafePointer<AudioStreamBasicDescription> = audioFile.processingFormat.streamDescription
        /// Audio file's audio description.
        let origAudioDesc: AudioStreamBasicDescription = origAudioDescPointer.pointee
        /// Audio description for the track to play, including interleaved conversion.
        var audioDesc: AudioStreamBasicDescription = origAudioDesc
        
        /// True if the audio is non-interleaved.
        let noninterleaved: Bool = origAudioDesc.mFormatFlags & kAudioFormatFlagIsNonInterleaved > 0
        /// Audio converter to convert non-interleaved audio.
        var converter: AudioConverterRef?
        // If the audio data is non-interleaved, it needs to be converted to interleaved format to be streamed.
        /// Audio description for the converted audio if non-interleaved is converted to interleaved. Initialized outside the if clause to prevent deallocation.
        var convertedAudioDesc: AudioStreamBasicDescription = AudioStreamBasicDescription()
        if noninterleaved {
            convertedAudioDesc.mSampleRate = origAudioDesc.mSampleRate
            convertedAudioDesc.mFormatID = origAudioDesc.mFormatID
            convertedAudioDesc.mBitsPerChannel = origAudioDesc.mBitsPerChannel
            convertedAudioDesc.mChannelsPerFrame = origAudioDesc.mChannelsPerFrame
            convertedAudioDesc.mFramesPerPacket = origAudioDesc.mFramesPerPacket
            convertedAudioDesc.mReserved = origAudioDesc.mReserved
            
            convertedAudioDesc.mFormatFlags = origAudioDesc.mFormatFlags & ~kAudioFormatFlagIsNonInterleaved
            // Interleaved audio combines all channels in the same frame, different from non-interleaved audio.
            convertedAudioDesc.mBytesPerFrame = origAudioDesc.mBytesPerFrame * convertedAudioDesc.mChannelsPerFrame
            convertedAudioDesc.mBytesPerPacket = convertedAudioDesc.mBytesPerFrame * convertedAudioDesc.mFramesPerPacket
            
            audioDesc = convertedAudioDesc
            
            /// Pointer to the non-interleaved audio converter.
            let converterPointer: UnsafeMutablePointer<AudioConverterRef?> = UnsafeMutablePointer<AudioConverterRef?>.allocate(capacity: MemoryLayout<AudioConverterRef>.size)
            /// Status code for creating an audio converter.
            let createStatus: OSStatus = AudioConverterNew(origAudioDescPointer, UnsafePointer(&audioDesc), converterPointer)
            if createStatus != 0 {
                throw MessageError("Failed to create converter for interleaved audio.", createStatus)
            }
            converter = converterPointer.pointee
        }
        
        do {
            try audioFile.read(into: origBuffer, frameCount: startReadFrames)
        } catch {
            throw MessageError("Failed to load audio file into buffer.", error)
        }
        
        /// Size of the audio buffer in bytes.
        let bufferSize: UInt32 = audioDesc.mBytesPerFrame * UInt32(audioFile.length)
        audioBuffer = AudioBuffer(mNumberChannels: audioDesc.mChannelsPerFrame, mDataByteSize: bufferSize, mData: malloc(Int(bufferSize)))
        
        try convertAndAddAudio(origBuffer: origBuffer, audioDesc: audioDesc, converter: converter, noninterleaved: noninterleaved, offset: 0)
        
        /// Status code for loading audio into the music player.
        var loadStatus: OSStatus = -1
        /// Number of frames in the audio file across all channels.
        let audioLength: AVAudioFramePosition = audioFile.length * Int64(audioDesc.mChannelsPerFrame)
        sampleRate = audioDesc.mSampleRate
        
        let audioData: UnsafeMutableRawPointer = audioBuffer!.mData!
        // Check for the data type of the audio and load it in the audio engine accordingly.
        if origBuffer.int32ChannelData != nil {
            loadStatus = load32BitAudio(audioData, audioLength, audioDesc)
        } else if origBuffer.int16ChannelData != nil {
            loadStatus = load16BitAudio(audioData, audioLength, audioDesc)
        } else if origBuffer.floatChannelData != nil {
            loadStatus = loadFloatAudio(audioData, audioLength, audioDesc)
        }
        
        if loadStatus != 0 {
            throw MessageError("Audio data is empty or not supported.", loadStatus)
        }
        
        try loadAudioAsync(audioFile: audioFile, loadBuffer: origBuffer, audioDesc: audioDesc, converter: converter, noninterleaved: noninterleaved, currentFramesRead: startReadFrames, processUuid: trackUuid)
        
        updateLoopPoints()
        
        try playTrack()
        
        NotificationCenter.default.post(name: .trackName, object: nil)
    }
    
    /// Adds the next portion of audio to the audio buffer. Converts non-interleaved to interleaved audio if necessary.
    /// - parameter origBuffer: Audio buffer to get audio data from.
    /// - parameter audioDesc: Audio description of the audio file.
    /// - parameter converter: Audio converter to convert non-interleaved audio.
    /// - parameter noninterleaved: True if the audio is non-interleaved.
    /// - parameter offset: Offset for inserting converted data into the class-level audio buffer.
    func convertAndAddAudio(origBuffer: AVAudioPCMBuffer, audioDesc: AudioStreamBasicDescription, converter: AudioConverterRef?, noninterleaved: Bool, offset: Int) throws {
        if noninterleaved {
            try convertToInterleavedAudio(origBuffer: origBuffer, audioDesc: audioDesc, converter: converter!, offset: offset)
        } else {
            addToAudioBuffer(buffer: origBuffer.audioBufferList.pointee.mBuffers, offset: offset)
            print("Warning: Interleaved audio is untested.")
        }
    }
    
    /// Takes noninterleaved audio data from a buffer and converts it to interleaved audio data. This data is stored in the class-level audio buffer.
    /// - parameter origBuffer: Noninterleaved audio buffer to get audio data from.
    /// - parameter audioDesc: Audio description for the converted audio data.
    /// - parameter converter: Audio converter to convert audio data with.
    /// - parameter offset: Offset for inserting converted data into the class-level audio buffer.
    func convertToInterleavedAudio(origBuffer: AVAudioPCMBuffer, audioDesc: AudioStreamBasicDescription, converter: AudioConverterRef, offset: Int) throws {
        /// Internal audio buffer list from the audio buffer.
        let origAudioBuffer: AudioBufferList = origBuffer.audioBufferList.pointee
        // Allocate memory for a buffer to store the converted audio data.
        // Combine all buffers from the non-interleaved audio into a single buffer.
        /// Audio buffer list to store converted interleaved audio in.
        let newAudioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
        /// Size of the converted audio buffer in bytes.
        let newBufferSize: UInt32 = origAudioBuffer.mBuffers.mDataByteSize * origAudioBuffer.mNumberBuffers

        /// Audio buffer to store converted interleaved audio in.
        let newAudioBuffer: AudioBuffer = AudioBuffer(mNumberChannels: audioDesc.mChannelsPerFrame, mDataByteSize: newBufferSize, mData: malloc(Int(newBufferSize)))
        newAudioBufferList[0] = newAudioBuffer
    
        /// Status code from audio converter for interleaved audio.
        let convertStatus: OSStatus = AudioConverterConvertComplexBuffer(converter, origBuffer.frameLength, origBuffer.audioBufferList, newAudioBufferList.unsafeMutablePointer)
        if convertStatus != 0 {
            throw MessageError("Failed to convert to interleaved audio.", convertStatus)
        }
        
        addToAudioBuffer(buffer: newAudioBuffer, offset: offset)
        free(newAudioBuffer.mData)
    }
    
    /// Transfers audio data from an audio buffer to the class-level audio buffer.
    /// - parameter buffer: Audio buffer to transfer data from.
    /// - parameter offset: Offset for inserting data into the class-level audio buffer.
    func addToAudioBuffer(buffer: AudioBuffer, offset: Int) {
        /// Memory address to start copying audio data into the class-level buffer.
        let dataOffset: UnsafeMutableRawPointer = audioBuffer!.mData! + offset
        dataOffset.copyMemory(from: buffer.mData!, byteCount: Int(buffer.mDataByteSize))
    }
    
    /// Loads the next portion of audio asynchronously from the main thread.
    /// - parameter audioFile: The audio file being loaded.
    /// - parameter loadBuffer: Audio buffer to load audio samples into.
    /// - parameter audioDesc: Audio description of the audio file.
    /// - parameter converter: Audio converter to convert non-interleaved audio.
    /// - parameter noninterleaved: True if the audio is non-interleaved.
    /// - parameter currentFramesRead: The number of audio frames that have been read so far.
    /// - parameter processUuid: The UUID of the audio track process. If the track changes, this will not match and the async task will cancel.
    func loadAudioAsync(audioFile: AVAudioFile, loadBuffer: AVAudioPCMBuffer, audioDesc: AudioStreamBasicDescription, converter: AudioConverterRef?, noninterleaved: Bool, currentFramesRead: AVAudioFrameCount, processUuid: UUID) throws {
        if currentFramesRead >= audioFile.length {
            try disposeConverter(converter: converter)
            return
        }
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            do {
                try audioFile.read(into: loadBuffer, frameCount: MusicPlayer.FRAME_READ_INCREMENT)

                self.bufferLock.wait()
                if processUuid == self.trackUuid {
                    try self.convertAndAddAudio(origBuffer: loadBuffer, audioDesc: audioDesc, converter: converter, noninterleaved: noninterleaved, offset: Int(currentFramesRead * audioDesc.mBytesPerFrame))
                    self.bufferLock.signal()
                } else {
                    // If the process UUID doesn't match, the track has changed. Cancel loading the audio.
                    self.bufferLock.signal()
                    try self.disposeConverter(converter: converter)
                    return
                }
            
                // Recursively load audio until the file is fully read.
                try self.loadAudioAsync(audioFile: audioFile, loadBuffer: loadBuffer, audioDesc: audioDesc, converter: converter, noninterleaved: noninterleaved, currentFramesRead: currentFramesRead + MusicPlayer.FRAME_READ_INCREMENT, processUuid: processUuid)
            } catch {
                print("Error loading audio asynchronously:", error.localizedDescription)
                return
            }
        }
    }
    
    /// Adds the next portion of audio to the audio buffer.
    /// - parameter loadBuffer: Audio buffer to load audio samples into.
    /// - parameter audioDesc: Audio description of the audio file.
    /// - parameter converter: Audio converter to convert non-interleaved audio.
    /// - parameter noninterleaved: True if the audio is non-interleaved.
    /// - parameter currentFramesRead: The number of audio frames that have been read so far.
    /// - parameter processUuid: The UUID of the audio track process. If the track changes, this will not match and the async task will cancel.
    func addAudioAsync(loadBuffer: AVAudioPCMBuffer, audioDesc: AudioStreamBasicDescription, converter: AudioConverterRef?, noninterleaved: Bool, currentFramesRead: AVAudioFrameCount, processUuid: UUID) throws {
        defer { bufferLock.signal() }
        if processUuid == self.trackUuid {
            try self.convertAndAddAudio(origBuffer: loadBuffer, audioDesc: audioDesc, converter: converter, noninterleaved: noninterleaved, offset: Int(currentFramesRead * audioDesc.mBytesPerFrame))
        } else {
            // If the process UUID doesn't match, the track has changed. Cancel loading the audio.
            try self.disposeConverter(converter: converter)
        }
    }
    
    /// Disposes an audio converter.
    /// - parameter converter: The converter to dispose.
    func disposeConverter(converter: AudioConverterRef?) throws {
        if let converter: AudioConverterRef = converter {
            /// Status code for disposing the audio converter.
            let deallocateStatus: OSStatus = AudioConverterDispose(converter)
            if deallocateStatus != 0 {
                throw MessageError("Failed to deallocate converter for interleaved audio.", deallocateStatus)
            }
        }
    }
    
    /// Starts playing the currently loaded track.
    func playTrack() throws {
        if !playing {
            fadeMultiplier = 1
            updateVolume()
            playing = true
            /// Status code for playing audio.
            let playStatus: OSStatus = playAudio()
            if playStatus != 0 {
                throw MessageError("Failed to play audio.", playStatus)
            }
            startShuffleTimer()
        }
    }
    
    /// Stops playing the currently loaded track.
    func stopTrack() throws {
        if playing {
            playing = false
            stopShuffleTimer()
            /// Status code for stopping audio.
            let stopStatus: OSStatus = stopAudio()
            if stopStatus != 0 {
                throw MessageError("Failed to stop audio.", stopStatus)
            }
        }
    }
    
    /// Updates the loop start/end within the audio engine.
    func updateLoopPoints() {
        setLoopPoints((Int64) (currentTrack.loopStart * sampleRate), (Int64) (currentTrack.loopEnd * sampleRate))
    }
    
    /// Updates the volume multiplier within the audio engine.
    func updateVolume() {
        setVolumeMultiplier(currentTrack.volumeMultiplier * MusicSettings.settings.masterVolume * fadeMultiplier)
    }
    
    /// Saves the currently configured volume multiplier to the database.
    func saveVolumeMultiplier() throws {
        try MusicData.data.updateVolumeMultiplier(track: currentTrack)
    }
    
    /// Saves the currently configured loop points to the database.
    func saveLoopPoints() throws {
        try MusicData.data.updateLoopPoints(track: currentTrack)
    }
    
    /// Chooses a random track from the current playlist and starts playing it.
    func randomizeTrack() throws {
        /// Tracks list to randomly choose from.
        let tracks: [MPMediaItem] = MediaPlayerUtils.getTracksInPlaylist()
        
        if tracks.count == 0 {
            throw MessageError("No compatible tracks found.")
        }
        
        /// Randomly chosen track to play.
        let randomTrack: MPMediaItem = tracks[Int.random(in: 0..<tracks.count)]

        try loadTrack(mediaItem: randomTrack)
        try playTrack()
    }
    
    /// Reloads all tracks in the current playlist. Used for database migration.
    func reloadAllTracks() throws {
        /// Tracks list to load.
        let tracks: [MPMediaItem] = MediaPlayerUtils.getTracksInPlaylist()
        
        try tracks.forEach { track in
            try loadTrack(mediaItem: track)
        }
    }
    
    /// Enables background audio playback for the app.
    func enableBackgroundAudio() throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw MessageError("Error enabling background audio.", error)
        }
    }
    
    /// Starts the timer used to shuffle tracks.
    func startShuffleTimer() {
        if shuffleTimer != nil {
            stopShuffleTimer()
        }
        if let shuffleTime: Double = MusicSettings.settings.calculateShuffleTime(track: currentTrack) {
            shuffleTimer = Timer.scheduledTimer(withTimeInterval: shuffleTime, repeats: false) { timer in
                do {
                    if let fadeDuration: Double = MusicSettings.settings.fadeDuration {
                        if fadeDuration > 0 {
                            self.fadeTimer = Timer.scheduledTimer(withTimeInterval: MusicPlayer.FADE_DECREMENT_TIME, repeats: true) { timer in
                                do {
                                    self.fadeMultiplier = max(0, self.fadeMultiplier - MusicPlayer.FADE_DECREMENT_TIME / fadeDuration)
                                    self.updateVolume()
                                    if self.fadeMultiplier <= 0 {
                                        try self.randomizeTrack()
                                    }
                                } catch {
                                    print("Error shuffling track:", error.localizedDescription)
                                }
                            }
                            return
                        }
                    }
                    try self.randomizeTrack()
                } catch {
                    print("Error shuffling track:", error.localizedDescription)
                }
            }
        }
    }
    
    /// Stops the timer used to shuffle tracks.
    func stopShuffleTimer() {
        shuffleTimer?.invalidate()
        shuffleTimer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
    }
}
