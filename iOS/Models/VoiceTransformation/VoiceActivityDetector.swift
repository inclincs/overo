//
//  VoiceActivityDetector.swift
//  overo-voice-transformation-ios
//
//  Created by 임재민 on 2021/08/10.
//  Edit by 유현우 on 2021/10/10.

import Foundation
import Accelerate

class VoiceActivityDetector {
    
    var threshold: Int
    var windowLength: Double
    var windowHopSize: Double
    
    init(threshold: Int, windowLength: Double, windowHopSize: Double) {
        self.threshold = threshold
        self.windowLength = windowLength
        self.windowHopSize = windowHopSize
    }
    
    
    func detect(audio: Audio) -> [Int] {
        return self.naiveFrameEnergyVAD(signals: audio.signals,
                                        signalLength: audio.signalLength,
                                        samplingRate: audio.samplingRate,
                                        threshold: threshold,
                                        windowLength: windowLength,
                                        windowHopSize: windowHopSize)
    }
    
    
    func naiveFrameEnergyVAD(signals: UnsafeMutablePointer<Double>,
                             signalLength: Int,
                             samplingRate: Int,
                             threshold: Int,
                             windowLength: Double,
                             windowHopSize: Double) -> [Int] {
        if (windowLength < windowHopSize) {
            print("ParameterError: windowLength must be larger than windowHop")
        }
        
        let frameLength = windowLength * Double(samplingRate)
        let frameStep = windowHopSize * Double(samplingRate)
        let framesOverlap = frameLength - frameStep
        
        let restSamples = abs(signalLength - Int(framesOverlap)) % abs(Int(frameLength) - Int(framesOverlap))
        let paddingLength = (Int(frameStep) - Int(restSamples)) * (restSamples != 0 ? 1 : 0)
        
        let totalSignalLength = signalLength + paddingLength
        let totalSignals = UnsafeMutablePointer<Double>.allocate(capacity: totalSignalLength)
        defer { totalSignals.deallocate() }
        
        totalSignals.initialize(repeating: 0, count: totalSignalLength)
        totalSignals.assign(from: signals, count: signalLength)
        
        
        let frameCount = (signalLength - Int(frameLength)) / Int(frameStep) + 1
        
        var logEnergies: [Double] = []
        var framePointer = totalSignals
        
        for _ in 0 ..< frameCount {
            let energy = calculateNormalizedShortTimeEnergy(framePointer, Int(frameLength))
            
            let E0 = 0.06
            let logEnergy = 10 * log10(energy / E0)
            
            logEnergies.append(logEnergy)
            
            framePointer = framePointer.advanced(by: Int(frameStep))
        }
        
        let medianFilteredEnergies = medianFilter1D(logEnergies, 5)
        
        let voiced: [Bool] = medianFilteredEnergies.map { $0 > Double(threshold) }
        
        let segmentedVads = segmentSilenceOrNot(voiced, windowLength)
        
        return segmentedVads
    }
    
    func calculateNormalizedShortTimeEnergy(_ frame: UnsafeMutablePointer<Double>, _ frameLength: Int) -> Double {
        return sumOfSquares(frame, frameLength) / Double(frameLength)
    }
    
    func sumOfSquares(_ frame: UnsafeMutablePointer<Double>, _ frameLength: Int) -> Double {
        let buf = UnsafeMutableBufferPointer<Double>(start: frame, count: frameLength)
        
        return buf.map { pow($0, 2.0) }.reduce(0.0, +)
    }
    
    func medianFilter1D(_ logEnergies: [Double], _ kernel_size: Int) -> [Double] {
        var medians: [Double] = []
        
        for i in 0 ..< logEnergies.count {
            let slice = Array(logEnergies[i ..< min(i + kernel_size, logEnergies.count)])
            
            medians.append(slice.sorted(by: <)[slice.count / 2])
        }
        
        return medians
    }
    
    func segmentSilenceOrNot(_ voiced: [Bool], _ windowLength: Double) -> [Int] {
        let silenceLengthThreshold = 0.25
        let silenceWindowCountThreshold = Int(silenceLengthThreshold / windowLength)
        
        var silenceVad: [Int] = [Int](repeating: 1, count: voiced.count)
        var silenceWindowCount = 0
        
        for i in 0 ..< voiced.count {
            if voiced[i] {
                if silenceWindowCount > silenceWindowCountThreshold {
                    silenceVad.replaceSubrange(
                        (i - silenceWindowCount) ..< i,
                        with: repeatElement(0, count: silenceWindowCount)
                    )
                }
                
                silenceWindowCount = 0
            }
            else {
                silenceWindowCount += 1
            }
        }
        
        return silenceVad
    }
}
