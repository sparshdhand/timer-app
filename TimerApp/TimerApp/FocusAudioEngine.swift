//
//  FocusAudioEngine.swift
//  TimerApp
//
//  Created by Sparsh on 30/05/26.
//

import Foundation
import AVFoundation
import Combine

enum AudioPreset: String, CaseIterable, Identifiable {
    case off = "None"
    case brownNoise = "Brown Noise"
    case whiteNoise = "White Noise"
    case binauralBeats = "Binaural Beats"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .off: return "Silent environment"
        case .brownNoise: return "Warm waterfall rumble"
        case .whiteNoise: return "Static speech blocker"
        case .binauralBeats: return "5Hz Theta focus waves"
        }
    }
}

class FocusAudioEngine: ObservableObject {
    @Published var activePreset: AudioPreset = .off {
        didSet {
            updatePreset()
        }
    }
    @Published var volume: Double = 0.4 {
        didSet {
            engineVolumeNode?.volume = Float(volume)
        }
    }
    
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var engineVolumeNode: AVAudioMixerNode?
    
    // Noise state accumulators
    private var brownNoiseLastOut: Float = 0.0
    private var binauralThetaLeft: Float = 0.0
    private var binauralThetaRight: Float = 0.0
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        
        // Setup volume node
        let volumeNode = AVAudioMixerNode()
        engine.attach(volumeNode)
        engine.connect(volumeNode, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))
        volumeNode.volume = Float(volume)
        self.engineVolumeNode = volumeNode
        self.engine = engine
    }
    
    private func updatePreset() {
        stopPlaying()
        
        guard activePreset != .off else { return }
        
        let preset = activePreset
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
        
        // Reset state
        brownNoiseLastOut = 0.0
        binauralThetaLeft = 0.0
        binauralThetaRight = 0.0
        
        let sourceNode = AVAudioSourceNode { [weak self] (_, _, frameCount, audioBufferList) -> OSStatus in
            guard let self = self else { return noErr }
            
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannel = buffers[0].mData?.assumingMemoryBound(to: Float.self)
            let rightChannel = buffers[1].mData?.assumingMemoryBound(to: Float.self)
            
            let sampleRate: Float = 44100.0
            let leftFreq: Float = 140.0
            let rightFreq: Float = 145.0 // 5Hz difference for Theta binaural brain entrainment
            
            for frame in 0..<Int(frameCount) {
                var leftSample: Float = 0.0
                var rightSample: Float = 0.0
                
                switch preset {
                case .whiteNoise:
                    let noise = Float.random(in: -1.0...1.0)
                    leftSample = noise * 0.15
                    rightSample = noise * 0.15
                    
                case .brownNoise:
                    let whiteLeft = Float.random(in: -1.0...1.0)
                    let whiteRight = Float.random(in: -1.0...1.0)
                    
                    // Simple integration with loss (first-order low-pass filter)
                    self.brownNoiseLastOut = (self.brownNoiseLastOut + (0.02 * whiteLeft)) / 1.02
                    let noiseVal = self.brownNoiseLastOut * 2.8 // scale warm frequency
                    
                    leftSample = noiseVal * 0.25
                    rightSample = noiseVal * 0.25
                    
                case .binauralBeats:
                    // Left ear sine wave
                    leftSample = sin(self.binauralThetaLeft) * 0.2
                    self.binauralThetaLeft += 2.0 * .pi * leftFreq / sampleRate
                    if self.binauralThetaLeft > 2.0 * .pi { self.binauralThetaLeft -= 2.0 * .pi }
                    
                    // Right ear sine wave
                    rightSample = sin(self.binauralThetaRight) * 0.2
                    self.binauralThetaRight += 2.0 * .pi * rightFreq / sampleRate
                    if self.binauralThetaRight > 2.0 * .pi { self.binauralThetaRight -= 2.0 * .pi }
                    
                default:
                    break
                }
                
                leftChannel?[frame] = leftSample
                rightChannel?[frame] = rightSample
            }
            
            return noErr
        }
        
        self.sourceNode = sourceNode
        
        guard let engine = engine, let volumeNode = engineVolumeNode else { return }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: volumeNode, format: format)
        
        do {
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            print("Failed to start AVAudioEngine: \(error)")
        }
    }
    
    private func stopPlaying() {
        guard let engine = engine else { return }
        
        if let sourceNode = sourceNode {
            engine.disconnectNodeInput(sourceNode)
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
            self.sourceNode = nil
        }
        
        if engine.isRunning {
            engine.pause()
        }
    }
    
    func playCompletionChime() {
        let systemSoundID: UInt32 = 1007 // Premium macOS SMS received alert sound
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
