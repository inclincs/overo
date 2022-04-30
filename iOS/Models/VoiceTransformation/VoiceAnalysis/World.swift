//
//  World.swift
//  Overo
//
//  Created by cnlab on 2021/07/15.
//

import Foundation
import world

class World {
    
//    struct VoiceFeature {
//        var f0: Array<Double>
//        var temporalPositions: Array<Double>
//        var spectrogram: Array<Array<Double>>
//        var aperiodicity: Array<Array<Double>>
//    }
    struct VoiceFeature {
        var f0: UnsafeMutablePointer<Double>
        var temporalPositions: UnsafeMutablePointer<Double>
        var spectrogram: UnsafeMutablePointer<UnsafeMutablePointer<Double>?>
        var aperiodicity: UnsafeMutablePointer<UnsafeMutablePointer<Double>?>
        var f0Length: Int
        var spectralLength: Int
        
        func deallocate() {
            f0.deallocate()
            temporalPositions.deallocate()
            for i in 0 ..< f0Length {
                spectrogram[i]?.deallocate()
            }
            spectrogram.deallocate()
            for i in 0 ..< f0Length {
                aperiodicity[i]?.deallocate()
            }
            aperiodicity.deallocate()
        }
    }
    
//    static func analyze(signals: UnsafeMutablePointer<Double>, signalLength: Int, samplingRate: Int) -> VoiceFeature {
////        let _x = UnsafeMutablePointer<Double>.allocate(capacity: signalLength);
////        let x_length = signalLength
//
////        for i in 0 ..< x_length {
////            _x[i] = signals[i]
////        }
//
//        let _voice_feature = UnsafeMutablePointer<world.voicefeature>.allocate(capacity: 1)
//
//
//        world.analyze(signals, Int32(signalLength), Int32(samplingRate), _voice_feature)
//
//
//        let voice_feature = _voice_feature.pointee
//
//        let f0_length = Int(voice_feature.f0_length)
//        let spectral_length = Int(voice_feature.spectral_length)
//
//        var f0: Array<Double> = []
//        var temporalPositions: Array<Double> = []
//        var spectrogram: Array<Array<Double>> = []
//        var aperiodicity: Array<Array<Double>> = []
//
//        for i in 0 ..< f0_length {
//            f0.append(voice_feature.f0[i])
//            temporalPositions.append(voice_feature.temporal_positions[i])
//
//            var sp: Array<Double> = []
//            var ap: Array<Double> = []
//
//            for j in 0 ..< spectral_length {
//                sp.append(voice_feature.spectrogram[i]![j])
//                ap.append(voice_feature.aperiodicity[i]![j])
//            }
//
//            spectrogram.append(sp)
//            aperiodicity.append(ap)
//        }
//
//
////        voice_feature.f0.deallocate()
////        voice_feature.temporal_positions.deallocate()
////        for i in 0 ..< f0_length {
////            voice_feature.spectrogram[i]?.deallocate()
////        }
////        voice_feature.spectrogram.deallocate()
////        for i in 0 ..< f0_length {
////            voice_feature.aperiodicity[i]?.deallocate()
////        }
////        voice_feature.aperiodicity.deallocate()
////
////        _voice_feature.deallocate()
//
////        _x.deallocate()
//
//
////        return VoiceFeature(f0: f0,
////                            temporalPositions: temporalPositions,
////                            spectrogram: spectrogram,
////                            aperiodicity: aperiodicity)
//
//        return VoiceFeature(f0: voice_feature.f0,
//                            temporalPositions: voice_feature.temporal_positions,
//                            spectrogram: voice_feature.spectrogram,
//                            aperiodicity: voice_feature.aperiodicity,
//                            f0Length: Int(voice_feature.f0_length),
//                            spectralLength: Int(voice_feature.spectral_length))
//    }

//    static func synthesize(feature: VoiceFeature, samplingRate: Int) -> (UnsafeMutablePointer<Double>, Int) {
//        let _voice_feature = UnsafeMutablePointer<world.voicefeature>.allocate(capacity: 1)
//
//
//        let f0_length = feature.f0.count
//
//        let _f0 = UnsafeMutablePointer<Double>.allocate(capacity: f0_length)
//
//        feature.f0.enumerated().forEach { _f0[$0] = $1 }
//
//        let _temporal_positions = UnsafeMutablePointer<Double>.allocate(capacity: f0_length)
//
//        feature.temporalPositions.enumerated().forEach { _temporal_positions[$0] = $1 }
//
//        let _spectrogram = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: feature.spectrogram.count)
//
//        for i in 0 ..< feature.spectrogram.count {
//            _spectrogram[i] = UnsafeMutablePointer<Double>.allocate(capacity: feature.spectrogram[i].count)
//
//            feature.spectrogram[i].enumerated().forEach { _spectrogram[i]![$0] = $1 }
//        }
//
//        let _aperiodicity = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: feature.aperiodicity.count)
//
//        for i in 0 ..< feature.aperiodicity.count {
//            _aperiodicity[i] = UnsafeMutablePointer<Double>.allocate(capacity: feature.aperiodicity[i].count)
//
//            feature.aperiodicity[i].enumerated().forEach { _aperiodicity[i]![$0] = $1 }
//        }
//
//
//        _voice_feature[0].f0 = _f0
//        _voice_feature[0].f0_length = Int32(f0_length)
//        _voice_feature[0].temporal_positions = _temporal_positions
//        _voice_feature[0].spectrogram = _spectrogram
//        _voice_feature[0].aperiodicity = _aperiodicity
//        _voice_feature[0].spectral_length = Int32(feature.spectrogram.count)
//
//        let frame_period = 5.0
//        let y_length = Int(Double(f0_length - 1) * frame_period / 1000.0 * Double(samplingRate) + 1.0)
//
//        let _y = UnsafeMutablePointer<Double>.allocate(capacity: y_length)
//        for i in 0 ..< y_length {
//            _y[i] = 0
//        }
//
//
//        world.synthesize(_voice_feature, Int32(samplingRate), Int32(y_length), _y)
//
//
//        var signals: [Double] = []
//
//        for i in 0 ..< y_length {
//            signals.append(_y[i])
//        }
//
//        let signalLength = y_length
//
//        _y.deallocate()
//
//        for i in 0 ..< feature.aperiodicity.count {
//            _aperiodicity[i]?.deallocate()
//        }
//        _aperiodicity.deallocate()
//        for i in 0 ..< feature.spectrogram.count {
//            _spectrogram[i]?.deallocate()
//        }
//        _spectrogram.deallocate()
//        _f0.deallocate()
//
//        _voice_feature.deallocate()
//
//
//        return (_y, signalLength)
//    }
    
    static func analyze(signals: UnsafeMutablePointer<Double>, signalLength: Int, samplingRate: Int) -> VoiceFeature {
        let _voice_feature = UnsafeMutablePointer<world.voicefeature>.allocate(capacity: 1)

        world.analyze(signals, Int32(signalLength), Int32(samplingRate), _voice_feature)


        let voice_feature = _voice_feature.pointee

        return VoiceFeature(f0: voice_feature.f0,
                            temporalPositions: voice_feature.temporal_positions,
                            spectrogram: voice_feature.spectrogram,
                            aperiodicity: voice_feature.aperiodicity,
                            f0Length: Int(voice_feature.f0_length),
                            spectralLength: Int(voice_feature.spectral_length))
    }
    
    static func synthesize(feature: VoiceFeature, samplingRate: Int) -> (UnsafeMutablePointer<Double>, Int) {
        let _voice_feature = UnsafeMutablePointer<world.voicefeature>.allocate(capacity: 1)
        defer { _voice_feature.deallocate() }
        
        _voice_feature.pointee.f0 = feature.f0
        _voice_feature.pointee.temporal_positions = feature.temporalPositions
        _voice_feature.pointee.spectrogram = feature.spectrogram
        _voice_feature.pointee.aperiodicity = feature.aperiodicity
        _voice_feature.pointee.f0_length = Int32(feature.f0Length)
        _voice_feature.pointee.spectral_length = Int32(feature.spectralLength)
        
        
        let frame_period = 5.0
        let y_length = Int(Double(feature.f0Length - 1) * frame_period / 1000.0 * Double(samplingRate) + 1.0)
        
        let _y = UnsafeMutablePointer<Double>.allocate(capacity: y_length)
        defer { _y.deallocate() }
        _y.initialize(repeating: 0, count: y_length)
        
        
        world.synthesize(_voice_feature, Int32(samplingRate), Int32(y_length), _y)
        
        
        let signals = UnsafeMutablePointer<Double>.allocate(capacity: y_length)
        signals.assign(from: _y, count: y_length)
        
        let signalLength = y_length
        
        
        return (signals, signalLength)
    }
}
