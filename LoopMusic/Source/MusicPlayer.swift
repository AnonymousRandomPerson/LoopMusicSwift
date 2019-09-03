import AVFoundation
import CoreAudio
import Foundation

/// Handles playback and looping of music tracks.
class MusicPlayer {
    
    /// The track currently loaded in the music player.
    private(set) var currentTrack: MusicTrack
    
    /// Initializes a music player with a blank track.
    init() {
        currentTrack = MusicTrack(url: URL(fileURLWithPath: ""), loopStart: 0, loopEnd: 0)
    }
    
    /// Loads a track into the music player based on its database track ID.
    /// - parameter trackId: The database track ID of the track to load.
    func loadTrack(trackId: String) throws {
        let url: URL = Bundle.main.url(forResource: "DL3 Minigame", withExtension: "m4a") ?? URL(fileURLWithPath: "")
        currentTrack = MusicTrack(url: url, loopStart: 160098, loopEnd: 898068)
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: url)
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
                throw MessageError(String(format: "Failed to create converter for interleaved audio. Status: %d", createStatus))
            }
            
            // Allocate memory for a buffer to store the converted audio data.
            // Combine all buffers from the non-interleaved audio into a single buffer.
            let origAudioBuffer: AudioBufferList = origBuffer.audioBufferList.pointee
            let newAudioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
            let bufferSize: UInt32 = origAudioBuffer.mBuffers.mDataByteSize * origAudioBuffer.mNumberBuffers
            // TODO Free this data.
            newAudioBufferList[0] = AudioBuffer(mNumberChannels: convertedAudioDesc.mChannelsPerFrame, mDataByteSize: bufferSize, mData: malloc(Int(bufferSize)))
            
            if let converter: AudioConverterRef = converterPointer.pointee {
                let convertStatus: OSStatus = AudioConverterConvertComplexBuffer(converter, origBuffer.frameLength, audioBuffer, newAudioBufferList.unsafeMutablePointer)
                if convertStatus != 0 {
                    throw MessageError(String(format: "Failed to convert to interleaved audio. Status: %d", convertStatus))
                }
                
                audioBuffer = newAudioBufferList.unsafePointer
                
                let deallocateStatus: OSStatus = AudioConverterDispose(converter)
                if deallocateStatus != 0 {
                    throw MessageError(String(format: "Failed to deallocate converter for interleaved audio. Status: %d", deallocateStatus))
                }
            } else {
                throw MessageError("Failed to load converter for interleaved audio.")
            }
        }
        
        var loadStatus: OSStatus = -1
        if let audioData: UnsafeMutableRawPointer = audioBuffer.pointee.mBuffers.mData {
            // Check for the data type of the audio and load it in the audio engine accordingly.
            if origBuffer.int32ChannelData != nil {
                loadStatus = load32BitAudio(audioData, audioFile.length, audioDesc)
            } else if origBuffer.int16ChannelData != nil {
                loadStatus = load16BitAudio(audioData, audioFile.length, audioDesc)
            } else if origBuffer.floatChannelData != nil {
                loadStatus = loadFloatAudio(audioData, audioFile.length, audioDesc)
            }
        }
        if loadStatus != 0 {
            throw MessageError(String(format: "Audio data is empty or not supported. Status: %d", loadStatus))
        }
        
        print("Loaded")
        playAudio()
        print("Playing")
    }
}
