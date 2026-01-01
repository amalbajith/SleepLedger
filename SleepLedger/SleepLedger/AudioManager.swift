//
//  AudioManager.swift
//  SleepLedger
//
//  Manages audio session for background execution (silent audio)
//  and smart alarm playback.
//

import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var audioEngine: AVAudioEngine?
    private var silentPlayerNode: AVAudioPlayerNode?
    private var alarmPlayerNode: AVAudioPlayerNode?
    
    // Check if audio is running
    var isRunning: Bool {
        return audioEngine?.isRunning ?? false
    }
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("❌ Audio Session Setup Error: \(error)")
        }
    }
    
    // MARK: - Keep Alive (Silent Audio)
    
    func startSilentAudio() {
        if audioEngine == nil {
            setupEngine()
        }
        
        guard let engine = audioEngine, let silentNode = silentPlayerNode else { return }
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("❌ Audio Engine Start Error: \(error)")
            }
        }
        
        if !silentNode.isPlaying {
            silentNode.play()
            print("🔊/🔇 Silent audio started (Keeping app alive)")
        }
    }
    
    func stopSilentAudio() {
        silentPlayerNode?.stop()
        
        // Only stop engine if alarm isn't playing
        if !(alarmPlayerNode?.isPlaying ?? false) {
            audioEngine?.stop()
            print("🛑 Audio engine stopped")
        }
    }
    
    // MARK: - Alarm
    
    func playAlarm() {
        // Ensure engine is running
        startSilentAudio()
        
        guard let alarmNode = alarmPlayerNode else { return }
        
        // Ramp up volume? For now, just play.
        alarmNode.volume = 1.0
        
        if !alarmNode.isPlaying {
            alarmNode.play()
            print("⏰ ALARM PLAYING!")
        }
    }
    
    func stopAlarm() {
        alarmPlayerNode?.stop()
        print("🔕 Alarm stopped")
        
        // Also stop silent audio if we are waking up
        stopSilentAudio() 
    }
    
    // MARK: - Engine Setup
    
    private func setupEngine() {
        let engine = AVAudioEngine()
        let silentNode = AVAudioPlayerNode()
        let alarmNode = AVAudioPlayerNode()
        
        engine.attach(silentNode)
        engine.attach(alarmNode)
        
        let format = engine.outputNode.inputFormat(forBus: 0)
        
        // 1. Silent Buffer (Infinite Loop)
        if let silentBuffer = createSilenceBuffer(format: format) {
            engine.connect(silentNode, to: engine.mainMixerNode, format: format)
            silentNode.scheduleBuffer(silentBuffer, at: nil, options: .loops, completionHandler: nil)
            silentNode.volume = 0.0 // Ensure it's silent
        }
        
        // 2. Alarm Buffer (Sine Wave Tone)
        if let alarmBuffer = createSineWaveBuffer(format: format, frequency: 440.0) { // A4 Note
            engine.connect(alarmNode, to: engine.mainMixerNode, format: format)
            alarmNode.scheduleBuffer(alarmBuffer, at: nil, options: .loops, completionHandler: nil)
            alarmNode.volume = 1.0
        }
        
        audioEngine = engine
        silentPlayerNode = silentNode
        alarmPlayerNode = alarmNode
        
        do {
            try engine.start()
        } catch {
            print("❌ Engine Start Error: \(error)")
        }
    }
    
    private func createSilenceBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // 1 second of silence
        let frameCount = AVAudioFrameCount(format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        // Zero out the channel data effectively creates silence
        if let channelData = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                let bytes = frameCount * UInt32(MemoryLayout<Float>.size)
                memset(channelData[channel], 0, Int(bytes))
            }
        }
        
        return buffer
    }
    
    private func createSineWaveBuffer(format: AVAudioFormat, frequency: Float) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate) // 1 second loop
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let amplitude: Float = 0.5 // Half volume to avoid clipping
        
        if let channelData = buffer.floatChannelData {
            for frame in 0..<Int(frameCount) {
                let time = Float(frame) / sampleRate
                let value = sin(2.0 * Float.pi * frequency * time) * amplitude
                
                // Write to all channels
                for channel in 0..<Int(format.channelCount) {
                    channelData[channel][frame] = value
                }
            }
        }
        
        return buffer
    }
}
