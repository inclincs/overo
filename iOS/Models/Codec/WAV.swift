
//
//  WAV.swift
//  Overo
//
//  Created by cnlab on 2021/07/21.
//

import Foundation
import wav

struct Audio {
    var signals: UnsafeMutablePointer<Double>
    var signalLength: Int
    var samplingRate: Int
}

class WAV {
    
    static func save(_ filePath: String, _ audio: Audio) {
        let wavfileWrapper = UnsafeMutablePointer<wav.wavfile>.allocate(capacity: 1)
        defer { wavfileWrapper.deallocate() }
        
        let channels = 1
        let bit_per_sample = 16
        let block_alignment = channels * bit_per_sample / 8
        let byte_rate = audio.samplingRate * block_alignment
        
        wavfileWrapper.pointee.tag = 1
        wavfileWrapper.pointee.channels = UInt16(channels)
        wavfileWrapper.pointee.sampling_rate = UInt32(audio.samplingRate)
        wavfileWrapper.pointee.byte_rate = UInt32(byte_rate)
        wavfileWrapper.pointee.block_alignment = UInt16(block_alignment)
        wavfileWrapper.pointee.bit_per_sample = UInt16(bit_per_sample)
        wavfileWrapper.pointee.signals = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: 1)
        defer { wavfileWrapper.pointee.signals.deallocate() }
        
        for i in 0 ..< channels {
            wavfileWrapper.pointee.signals[i] = UnsafeMutablePointer<Double>.allocate(capacity: audio.signalLength)
        }
        defer {
            for i in 0 ..< channels {
                wavfileWrapper.pointee.signals[i]?.deallocate()
            }
        }
        wavfileWrapper.pointee.signals[0]!.assign(from: audio.signals, count: audio.signalLength)
        wavfileWrapper.pointee.signal_length = Int32(audio.signalLength)

        
        wav.encode(filePath, wavfileWrapper)
    }
    
    static func load(_ filePath: String) -> Audio {
        let wavfileBuffer = UnsafeMutablePointer<wav.wavfile>.allocate(capacity: 1)
        defer { wavfileBuffer.deallocate() }
        
        
        wav.decode(filePath, wavfileBuffer)
        
        
        let wavfile = wavfileBuffer.pointee
        
        let samplingRate = Int(wavfile.sampling_rate)
        let signalLength = Int(wavfile.signal_length)
        let signals = UnsafeMutablePointer<Double>.allocate(capacity: signalLength)
        signals.assign(from: wavfile.signals[0]!, count: signalLength)
        
        
        return Audio(signals: signals, signalLength: signalLength, samplingRate: samplingRate)
    }
}

