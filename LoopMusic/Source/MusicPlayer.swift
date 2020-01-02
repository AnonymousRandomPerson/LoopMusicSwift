import AVFoundation
import CoreAudio
import Foundation
import MediaPlayer

/// Handles playback and looping of music tracks.
class MusicPlayer {
    
    /// The default number of frames to be read from an audio file when loading the initial portion of audio.
    static let START_READ_FRAMES: AVAudioFramePosition = AVAudioFramePosition(100000)
    
    /// The track currently loaded in the music player.
    private(set) var currentTrack: MusicTrack
    /// True if the player is currently playing a track.
    private(set) var playing: Bool = false
    /// The playlist to use for selecting tracks.
    private(set) var currentPlaylist: String = "LoopMusic"

    /// Timer used to shuffle tracks after playing for a while.
    private var shuffleTimer: Timer?
    
    /// Sample rate of the currently loaded track.
    private var sampleRate: Double = 44100
    
    /// Audio data for the currently playing track.
    private var audioBuffer: AudioBuffer?
    /// True if the current audio track was converted manually.
    private var manuallyAllocatedBuffer: Bool = false
    
    /// Initializes a music player with a blank track.
    init() {
        currentTrack = MusicTrack.BLANK_MUSIC_TRACK
    }
    
    /// Loads a track into the music player.
    /// - parameter mediaItem: The audio track to play.
    func loadTrack(mediaItem: MPMediaItem) throws {
        try stopTrack()
        
        // Unload the buffer for the previous track.
        if let audioBuffer: AudioBuffer = audioBuffer {
            free(audioBuffer.mData)
        }
        
        currentTrack = try MusicData.data.loadTrack(mediaItem: mediaItem)
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: currentTrack.url)
        } catch let error as NSError {
            throw MessageError(error.localizedDescription)
        }
        
        let startReadFrames: AVAudioFrameCount = AVAudioFrameCount(max(audioFile.length, MusicPlayer.START_READ_FRAMES))
        guard let origBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: startReadFrames) else {
            throw MessageError("Audio is not in PCM format.")
        }
        
        let origAudioDescPointer: UnsafePointer<AudioStreamBasicDescription> = audioFile.processingFormat.streamDescription
        let origAudioDesc: AudioStreamBasicDescription = origAudioDescPointer.pointee
        var audioDesc: UnsafePointer<AudioStreamBasicDescription> = origAudioDescPointer
        
        let noninterleaved: Bool = origAudioDesc.mFormatFlags & kAudioFormatFlagIsNonInterleaved > 0
        var converter: AudioConverterRef?
        if noninterleaved {
            // If the audio data is non-interleaved, it needs to be converted to interleaved format to be streamed.
            var convertedAudioDesc: AudioStreamBasicDescription = AudioStreamBasicDescription()
            
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
            
            audioDesc = UnsafePointer(&convertedAudioDesc)
            
            let converterPointer: UnsafeMutablePointer<AudioConverterRef?> = UnsafeMutablePointer<AudioConverterRef?>.allocate(capacity: MemoryLayout<AudioConverterRef>.size)
            let createStatus: OSStatus = AudioConverterNew(origAudioDescPointer, audioDesc, converterPointer)
            if createStatus != 0 {
                throw MessageError(message: "Failed to create converter for interleaved audio.", statusCode: createStatus)
            }
            converter = converterPointer.pointee
        }
        
        do {
            try audioFile.read(into: origBuffer, frameCount: startReadFrames)
        } catch let error as NSError {
            throw MessageError(error.localizedDescription)
        }
        
        let bufferSize: UInt32 = audioDesc.pointee.mBytesPerFrame * UInt32(audioFile.length)
        audioBuffer = AudioBuffer(mNumberChannels: audioDesc.pointee.mChannelsPerFrame, mDataByteSize: bufferSize, mData: malloc(Int(bufferSize)))
        
        if (noninterleaved) {
            try convertToInterleavedAudio(origBuffer: origBuffer, audioDesc: audioDesc.pointee, converter: converter!, offset: 0)
        } else {
            addToAudioBuffer(buffer: origBuffer.audioBufferList.pointee.mBuffers, offset: 0)
            print("Warning: Interleaved audio is untested.")
        }
        
        var loadStatus: OSStatus = -1
        let audioLength: AVAudioFramePosition = audioFile.length * Int64(audioDesc.pointee.mChannelsPerFrame);
        sampleRate = audioDesc.pointee.mSampleRate
        
        let audioData: UnsafeMutableRawPointer = audioBuffer!.mData!
        // Check for the data type of the audio and load it in the audio engine accordingly.
        if origBuffer.int32ChannelData != nil {
            loadStatus = load32BitAudio(audioData, audioLength, audioDesc.pointee)
        } else if origBuffer.int16ChannelData != nil {
            loadStatus = load16BitAudio(audioData, audioLength, audioDesc.pointee)
        } else if origBuffer.floatChannelData != nil {
            loadStatus = loadFloatAudio(audioData, audioLength, audioDesc.pointee)
        }
        
        if loadStatus != 0 {
            throw MessageError(message: "Audio data is empty or not supported.", statusCode: loadStatus)
        }
        
        updateTrackSettings()
        
        try playTrack()
        
        NotificationCenter.default.post(name: .trackName, object: nil)
        
        // DispatchQueue.async(execute: )
    }
    
    /// Takes noninterleaved audio data from a buffer and converts it to interleaved audio data. This data is stored in the class-level audio buffer.
    /// - parameter origBuffer: Noninterleaved audio buffer to get audio data from.
    /// - parameter audioDesc: Audio description for the converted audio data.
    /// - parameter converter: Audio converter to convert audio data with.
    /// - parameter offset: Offset for inserting converted data into the class-level audio buffer.
    func convertToInterleavedAudio(origBuffer: AVAudioPCMBuffer, audioDesc: AudioStreamBasicDescription, converter: AudioConverterRef, offset: Int) throws {
        let origAudioBuffer: AudioBufferList = origBuffer.audioBufferList.pointee
        // Allocate memory for a buffer to store the converted audio data.
        // Combine all buffers from the non-interleaved audio into a single buffer.
        let newAudioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
        let newBufferSize: UInt32 = origAudioBuffer.mBuffers.mDataByteSize * origAudioBuffer.mNumberBuffers

        let newAudioBuffer: AudioBuffer = AudioBuffer(mNumberChannels: audioDesc.mChannelsPerFrame, mDataByteSize: newBufferSize, mData: malloc(Int(newBufferSize)))
        newAudioBufferList[0] = newAudioBuffer
    
        let convertStatus: OSStatus = AudioConverterConvertComplexBuffer(converter, origBuffer.frameLength, origBuffer.audioBufferList, newAudioBufferList.unsafeMutablePointer)
        if convertStatus != 0 {
            throw MessageError(message: "Failed to convert to interleaved audio.", statusCode: convertStatus)
        }
        
        let deallocateStatus: OSStatus = AudioConverterDispose(converter)
        if deallocateStatus != 0 {
            throw MessageError(message: "Failed to deallocate converter for interleaved audio.", statusCode: deallocateStatus)
        }
        
        addToAudioBuffer(buffer: newAudioBuffer, offset: offset)
        free(newAudioBuffer.mData)
    }
    
    /// Transfers audio data from an audio buffer to the class-level audio buffer.
    /// - parameter buffer: Audio buffer to transfer data from.
    /// - parameter offset: Offset for inserting data into the class-level audio buffer.
    func addToAudioBuffer(buffer: AudioBuffer, offset: Int) {
        let dataOffset: UnsafeMutableRawPointer = audioBuffer!.mData! + offset
        dataOffset.copyMemory(from: buffer.mData!, byteCount: Int(buffer.mDataByteSize))
    }
    
    /// Starts playing the currently loaded track.
    func playTrack() throws {
        if !playing {
            playing = true
            let playStatus: OSStatus = playAudio()
            if (playStatus != 0) {
                throw MessageError(message: "Failed to play audio.", statusCode: playStatus)
            }
        }
    }
    
    /// Stops playing the currently loaded track.
    func stopTrack() throws {
        if playing {
            playing = false
            let stopStatus: OSStatus = stopAudio()
            if stopStatus != 0 {
                throw MessageError(message: "Failed to stop audio.", statusCode: stopStatus)
            }
        }
    }
    
    /// Updates the loop start/end and volume multipliers within the audio engine.
    func updateTrackSettings() {
        setLoopPoints((Int64) (currentTrack.loopStart * sampleRate), (Int64) (currentTrack.loopEnd * sampleRate))
        setVolumeMultiplier(currentTrack.volumeMultiplier)
    }
    
    /// Chooses a random track from the current playlist and starts playing it.
    func randomizeTrack() throws {
        let query: MPMediaQuery = MPMediaQuery.playlists()
        query.filterPredicates = NSSet(object: MPMediaPropertyPredicate(value: currentPlaylist, forProperty: MPMediaItemPropertyTitle)) as? Set<MPMediaPredicate>
        var playlistTracks: [MPMediaItem]?
        if let playlists: [MPMediaItemCollection] = query.collections {
            for playlist in playlists {
                playlistTracks = playlist.items
                break
            }
        }
        
        var tracks: [MPMediaItem]
        if let playlistTracks: [MPMediaItem] = playlistTracks {
            tracks = playlistTracks
        } else if let allTracks = MPMediaQuery.songs().items {
            tracks = allTracks
        } else {
            throw MessageError("No tracks found.")
        }
        if tracks.count == 0 {
            throw MessageError("No tracks found.")
        }
        
        let randomTrack: MPMediaItem = tracks[Int.random(in: 0..<tracks.count)]

        try loadTrack(mediaItem: randomTrack)
        try playTrack()
    }
}
