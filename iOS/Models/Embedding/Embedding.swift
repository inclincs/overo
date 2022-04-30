//
//  Embedding.swift
//  Overo
//
//  Created by cnlab on 2021/08/06.
//

import Foundation
import embed

class Embedding {
    
    static func embedHash(_ audio: [Double], _ hashValue: Hash) -> [Double] {
        let wave_length = audio.count
        let wave = UnsafeMutablePointer<Double>.allocate(capacity: wave_length)
        
        audio.enumerated().forEach { wave[$0] = $1 }
    
        let hash_bit_length = hashValue.value.count * 8
        let hash_value = UnsafeMutablePointer<UInt8>.allocate(capacity: hashValue.value.count)
        
        hashValue.value.enumerated().forEach { hash_value[$0] = $1 }
        
        
        embed.embed_hash(wave, Int32(wave_length), hash_value, Int32(hash_bit_length))
        
        
        var result: [Double] = []
        
        for i in 0 ..< wave_length {
            result.append(wave[i])
        }
        
        hash_value.deallocate()
        wave.deallocate()
        
        return result
    }
    
//    static func test() {
//        let wave_length = 10000
//        let wave = UnsafeMutablePointer<Double>.allocate(capacity: wave_length)
//
//        for i in 0 ..< wave_length {
//            wave[i] = sin(Double(i) * 1000 * 2 * Double.pi / Double(wave_length))
//        }
//
//        let hash_bit_length = 256
//        let hash = UnsafeMutablePointer<UInt8>.allocate(capacity: hash_bit_length / 8)
//        for i in 0 ..< hash_bit_length / 8 {
//            hash[i] = UInt8.random(in: 0...255)
//        }
//
//        embed.embed_hash(wave, Int32(wave_length), hash, Int32(hash_bit_length))
//
//        let hash2 = UnsafeMutablePointer<UInt8>.allocate(capacity: hash_bit_length / 8)
//        for i in 0 ..< hash_bit_length / 8 {
//            hash2[i] = 0
//        }
//
//        embed.extract_hash(wave, Int32(wave_length), hash2, Int32(hash_bit_length))
//
////        for i in 0 ..< hash_bit_length / 8 {
////            if hash[i] != hash2[i] {
////                print("diff")
////                return
////            }
////            print(hash[i], separator: "", terminator: " ")
////            print(hash2[i], separator: "", terminator: "\n")
////        }
//
//
//
//        var signals: [Double] = []
//        for i in 0 ..< wave_length {
//            signals.append(wave[i])
////            if i < 10 {
////                print(wave[i])
////            }
//        }
//
//
//
//        WavFile.init(audioFilePath: nil, samplingRate: 8000, signals: signals).save(audioFilePath: "/Users/cnlab/Desktop/beep.wav")
//
////        print("finished")
//
//        let wf = WavFile.load(audioFilePath: "/Users/cnlab/Desktop/beep.wav")
//
//        let _signals = UnsafeMutablePointer<Double>.allocate(capacity: wf.signals.count)
//        for i in 0 ..< wf.signals.count {
//            _signals[i] = wf.signals[i]
////            if i < 10 {
////                print(wf.signals[i] - wave[i])
////            }
//        }
//
//        let hash3 = UnsafeMutablePointer<UInt8>.allocate(capacity: hash_bit_length / 8)
//        for i in 0 ..< hash_bit_length / 8 {
//            hash3[i] = 0
//        }
//
//        embed.extract_hash(_signals, Int32(wf.signals.count), hash3, Int32(hash_bit_length))
//
//        for i in 0 ..< hash_bit_length / 8 {
//            if hash[i] != hash3[i] {
//                print("diff2")
//                return
//            }
////            print(hash3[i], separator: "", terminator: " ")
//        }
//
//
//        wave.deallocate()
//
//        hash3.deallocate()
//        hash2.deallocate()
//        hash.deallocate()
//
//        print("finished")
//    }
}
