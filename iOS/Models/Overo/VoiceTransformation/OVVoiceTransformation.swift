//
//  OVVoiceTransformation.swift
//  Overo
//
//  Created by cnlab on 2021/10/15.
//

import Foundation
import Accelerate

class OVVoiceTransformation {
    
    struct VoiceTransformationResult {
        let audio: Audio
        let warpingParameters: [OVWarpingParameter]
    }
    
    func transform(audio: Audio) -> VoiceTransformationResult {
        // 1. analyze audio by world
        let voiceFeature = analyzeByWorld(audio: audio)
        
        // 2. detect voice activity segments
        let vadSegments = detectVoiceActivity(audio: audio,
                                              voiceFeature: voiceFeature)
        
        // 3. generate warping parameter
        let warpingParameters = generateRandomWarpingParameters(audio: audio,
                                                                voiceFeature: voiceFeature,
                                                                vadSegments: vadSegments)
        
        // 4. warp spectrogram
        let warpedSpectrogram = warpSpectrogram(audio: audio,
                                                voiceFeature: voiceFeature,
                                                warpingParameters: warpingParameters)
        
        // 5. generate transformed voice feature
        let transformedVoiceFeature = generateTransformedVoiceFeature(voiceFeature: voiceFeature,
                                                                      warpedSpectrogram: warpedSpectrogram)
        
        // 6. synthesize transformed audio by world
        let transformedAudio = synthesisByWorld(transformedVoiceFeature: transformedVoiceFeature,
                                                samplingRate: audio.samplingRate)
        
        
        return VoiceTransformationResult(audio: transformedAudio, warpingParameters: warpingParameters)
    }
    
    func analyzeByWorld(audio: Audio) -> World.VoiceFeature {
        return World.analyze(signals: audio.signals,
                             signalLength: audio.signalLength,
                             samplingRate: audio.samplingRate)
    }
    
    func detectVoiceActivity(audio: Audio, voiceFeature: World.VoiceFeature) -> [Int] {
        let voiceActivityDetector = VoiceActivityDetector(threshold: OVConfiguration.VADThreshold,
                                                          windowLength: OVConfiguration.VADWindowLength,
                                                          windowHopSize: OVConfiguration.VADwindowHopSize)
        var vad = voiceActivityDetector.detect(audio: audio)
        
        for _ in 0 ..< voiceFeature.f0Length - vad.count {
            vad.append(vad[vad.count - 1])
        }
        
        return vad
    }
    
    func generateRandomWarpingParameters(audio: Audio, voiceFeature: World.VoiceFeature, vadSegments: [Int]) -> [OVWarpingParameter] {
        var warpingParameters = [OVWarpingParameter]()
        var warpingParameter: OVWarpingParameter!

        for i in 0 ..< voiceFeature.f0Length {
            if i == 0 || vadSegments[i - 1] != vadSegments[i] {
                let (alpha, beta) = getProperParameterPair(samplingRate: audio.samplingRate)
                
                warpingParameter = OVWarpingParameter(startSampleIndex: i,
                                                      endSampleIndex: i + 1,
                                                      alpha: alpha,
                                                      beta: beta)
                
                warpingParameters.append(warpingParameter)
            } else {
                warpingParameter.endSampleIndex += 1
            }
        }

        return warpingParameters
    }
    
    func getProperParameterPair(samplingRate: Int) -> (Double, Double) {
        let nyqtFrequency = Double(samplingRate) / 2
        
        var alpha: Double = -1.0
        var beta: Double = -1.0
        
        while true {
            alpha = Double.random(in: 0...1)
            beta = Double.random(in: 0...1)

    //            let distortionStartMel = min(frequencyToMel(alpha * nyqtFrequency), frequencyToMel(beta * nyqtFrequency))
            let melDistortionIntensity = getMelDistortionIntensity(alpha * nyqtFrequency, beta * nyqtFrequency)
            
            if 200 <= melDistortionIntensity && melDistortionIntensity <= 300 {
                break
            }
        }
        
        return (alpha, beta)
    }
    
    func getMelDistortionIntensity(_ alpha: Double, _ beta: Double) -> Double {
        return abs(frequencyToMel(beta) - frequencyToMel(alpha))
    }
    
    func frequencyToMel(_ frequency: Double) -> Double {
        return (1000.0 / log(2)) * log(1 + frequency / 1000.0)
    }
    
    func warpSpectrogram(audio: Audio,
                         voiceFeature: World.VoiceFeature,
                         warpingParameters: [OVWarpingParameter]) -> UnsafeMutablePointer<UnsafeMutablePointer<Double>?> {
        let f0Length = voiceFeature.f0Length
        let spectralLength = voiceFeature.spectralLength
        
        let warpedSpectrogram = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: f0Length)
        
        for i in 0 ..< voiceFeature.f0Length {
            let alpha: Double = warpingParameters[i].alpha
            let beta: Double = warpingParameters[i].beta
            
            let warpedOmega = warpedOmegaWithPWLinear(alpha: alpha,
                                                      beta: beta,
                                                      fftLength: spectralLength)
            
            let spectrum = voiceFeature.spectrogram[i]!
            let warpedSpectrum: [Double] = warpSpectrum(spectrum: spectrum,
                                                        spectralLength: spectralLength,
                                                        warpedOmega: warpedOmega)

            warpedSpectrogram[i] = UnsafeMutablePointer<Double>.allocate(capacity: spectralLength)
            warpedSpectrogram[i]!.assign(from: warpedSpectrum, count: spectralLength)
        }

        return warpedSpectrogram
    }
    
    func warpedOmegaWithPWLinear(alpha: Double,
                                 beta: Double,
                                 fftLength: Int) -> [Double] {
        var warpedOmega = [Double]()
        let indexAlpha = alpha * Double(fftLength)
        
        for wi in 0 ..< fftLength {
            if wi <= Int(indexAlpha) {
                warpedOmega.append((beta / alpha) * Double(wi))
            } else {
                warpedOmega.append(beta * Double(fftLength) + ((1 - beta) / (1 - alpha)) * (Double(wi) - alpha * Double(fftLength)))
            }
        }
        
        return warpedOmega
    }
    
    func warpSpectrum(spectrum: UnsafeMutablePointer<Double>,
                      spectralLength: Int,
                      warpedOmega: [Double]) -> [Double] {
        let spectrumBuffer = UnsafeMutableBufferPointer<Double>(start: spectrum, count: spectralLength)
        let logSpectrum: [Float] = spectrumBuffer.map { Float(log($0) / 2.0) }
        
        let n = Int(vDSP_Length(warpedOmega.count))
        let stride = vDSP_Stride(1)
        
        var warpedLogSpectrum = [Float](repeating: 0, count: n)
        
        vDSP_vgenp(logSpectrum,
                   stride,
                   warpedOmega.map { Float($0) },
                   stride,
                   &warpedLogSpectrum,
                   stride,
                   UInt(n),
                   vDSP_Length(warpedOmega.count))
        
        return warpedLogSpectrum.map { Double(exp($0 * 2.0)) }
    }
    
    
    func generateTransformedVoiceFeature(voiceFeature: World.VoiceFeature,
                                         warpedSpectrogram: UnsafeMutablePointer<UnsafeMutablePointer<Double>?>) -> World.VoiceFeature {
        return World.VoiceFeature(f0: voiceFeature.f0,
                                  temporalPositions: voiceFeature.temporalPositions,
                                  spectrogram: warpedSpectrogram,
                                  aperiodicity: voiceFeature.aperiodicity,
                                  f0Length: voiceFeature.f0Length,
                                  spectralLength: voiceFeature.spectralLength)
    }

    
    func synthesisByWorld(transformedVoiceFeature voiceFeature: World.VoiceFeature, samplingRate: Int) -> Audio {
        let (signals, signalLength) = World.synthesize(feature: voiceFeature, samplingRate: samplingRate)
        
        return Audio(signals: signals, signalLength: signalLength, samplingRate: samplingRate)
    }
}
