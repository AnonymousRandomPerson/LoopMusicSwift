import AVFoundation
import CoreAudio
import Foundation
import MediaPlayer

/// Handles playback and looping of music tracks.
class MusicPlayer {
    
    /// The track currently loaded in the music player.
    private(set) var currentTrack: MusicTrack
    /// True if the player is currently playing a track.
    private(set) var playing: Bool = false
    /// The playlist to use for selecting tracks.
    private(set) var currentPlaylist: String = "LoopMusic"

    /// Timer used to shuffle tracks after playing for a while.
    private var shuffleTimer: Timer?
    
    /// If the current audio track was converted manually, this holds the audio buffer so memory can be freed when switching audio tracks.
    private var manuallyAllocatedBuffer: AudioBuffer?
    /// Sample rate of the currently loaded track.
    private var sampleRate: Double = 44100
    
    /// Initializes a music player with a blank track.
    init() {
        currentTrack = MusicTrack.BLANK_MUSIC_TRACK
    }
    
    /// Loads a track into the music player.
    /// - parameter mediaItem: The audio track to play.
    func loadTrack(mediaItem: MPMediaItem) throws {
        stopAudio()
        
        if (manuallyAllocatedBuffer != nil) {
            // New audio has been loaded, so it is safe to unload the old audio now.
            free(manuallyAllocatedBuffer?.mData)
        }
        
        currentTrack = try MusicData.data.loadTrack(mediaItem: mediaItem)
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: currentTrack.url)
        } catch let error as NSError {
            throw MessageError(error.localizedDescription)
        }
        
        guard let origBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
            throw MessageError("Audio is not in PCM format.")
        }
        do {
            try audioFile.read(into: origBuffer)
        } catch let error as NSError {
            throw MessageError(error.localizedDescription)
        }
        
        let origAudioDescPointer: UnsafePointer<AudioStreamBasicDescription> = audioFile.processingFormat.streamDescription
        let origAudioDesc: AudioStreamBasicDescription = origAudioDescPointer.pointee
        
        var audioBuffer: UnsafePointer<AudioBufferList> = origBuffer.audioBufferList
        var audioDesc: UnsafePointer<AudioStreamBasicDescription> = origAudioDescPointer
        
        let noninterleaved: Bool = origAudioDesc.mFormatFlags & kAudioFormatFlagIsNonInterleaved > 0
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
            
            // Allocate memory for a buffer to store the converted audio data.
            // Combine all buffers from the non-interleaved audio into a single buffer.
            let origAudioBuffer: AudioBufferList = origBuffer.audioBufferList.pointee
            let newAudioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
            let bufferSize: UInt32 = origAudioBuffer.mBuffers.mDataByteSize * origAudioBuffer.mNumberBuffers

            newAudioBufferList[0] = AudioBuffer(mNumberChannels: convertedAudioDesc.mChannelsPerFrame, mDataByteSize: bufferSize, mData: malloc(Int(bufferSize)))
            manuallyAllocatedBuffer = newAudioBufferList[0]
            
            if let converter: AudioConverterRef = converterPointer.pointee {
                let convertStatus: OSStatus = AudioConverterConvertComplexBuffer(converter, origBuffer.frameLength, audioBuffer, newAudioBufferList.unsafeMutablePointer)
                if convertStatus != 0 {
                    throw MessageError(message: "Failed to convert to interleaved audio.", statusCode: convertStatus)
                }
                
                audioBuffer = newAudioBufferList.unsafePointer
                
                let deallocateStatus: OSStatus = AudioConverterDispose(converter)
                if deallocateStatus != 0 {
                    throw MessageError(message: "Failed to deallocate converter for interleaved audio.", statusCode: deallocateStatus)
                }
            } else {
                throw MessageError("Failed to load converter for interleaved audio.")
            }
        }
        
        var loadStatus: OSStatus = -1
        let audioLength: AVAudioFramePosition = audioFile.length * Int64(audioDesc.pointee.mChannelsPerFrame);
        sampleRate = audioDesc.pointee.mSampleRate
        if let audioData: UnsafeMutableRawPointer = audioBuffer.pointee.mBuffers.mData {
            // Check for the data type of the audio and load it in the audio engine accordingly.
            if origBuffer.int32ChannelData != nil {
                loadStatus = load32BitAudio(audioData, audioLength, audioDesc)
            } else if origBuffer.int16ChannelData != nil {
                loadStatus = load16BitAudio(audioData, audioLength, audioDesc)
            } else if origBuffer.floatChannelData != nil {
                loadStatus = loadFloatAudio(audioData, audioLength, audioDesc)
            }
        }
        if loadStatus != 0 {
            throw MessageError(message: "Audio data is empty or not supported.", statusCode: loadStatus)
        }
        
        updateTrackSettings()
        
        NotificationCenter.default.post(name: .trackName, object: nil)
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
