//
//  OVBleep.swift
//  Overo
//
//  Created by cnlab on 2021/10/12.
//

import Foundation
import CryptoKit

class OVBleep {
    
    enum BleepError: Error {
        case signalDeallocated
    }
    
    var signals: UnsafeMutableBufferPointer<Double>
    var disposed: Bool
    
    init(signals: UnsafeMutableBufferPointer<Double>) {
        self.signals = signals
        self.disposed = false
    }
    
    
    func deallocate() {
        if self.disposed == false {
            self.signals.deallocate()
            self.disposed = true
        }
    }
    
    func copy() -> OVBleep? {
        if self.disposed { return nil }
        
        let copied = UnsafeMutableBufferPointer<Double>.allocate(capacity: signals.count)
        
        copied.baseAddress!.assign(from: signals.baseAddress!, count: signals.count)
        
        
        let bleep = OVBleep(signals: copied)
        
        return bleep
    }
    
    func embed(hash hashDigest: Insecure.SHA1Digest) throws {
        let bitPerSample = 16
        
        let hashBitLength = Insecure.SHA1Digest.byteCount * 8
        let embeddingBitLength = 8 // embed 8 bit for each signal into a bleep sound
        
        let requiredBleepLength = Int(ceil(Double(hashBitLength) / Double(embeddingBitLength)))
        
        hashDigest.withUnsafeBytes { hash in
            var sample = 0 as Int32
            
            var bit = 0 as UInt8
            var sampleByteIndex = 0 as Int
            var sampleBitIndex = 0 as Int
            var hashByteIndex = 0 as Int
            var hashBitIndex = 0 as Int
            
            for i in 0 ..< requiredBleepLength {
                sample = Int32(signals[i] * Double(1 << (bitPerSample - 1)))
                
                withUnsafeMutableBytes(of: &sample) { pSample in
                    sampleByteIndex = 0
                    sampleBitIndex = 0
                    
                    for _ in 0 ..< embeddingBitLength {
                        if hashByteIndex * 8 + hashBitIndex >= hashBitLength {
                            break
                        }
                        
                        bit = 1 << sampleBitIndex
                        
                        pSample[sampleByteIndex] &= ~bit
                        
                        if ((hash[hashByteIndex] >> hashBitIndex) & 1) == 1 {
                            pSample[sampleByteIndex] |= bit
                        }
                        
                        sampleBitIndex += 1
                        if sampleBitIndex >= 8 {
                            sampleBitIndex = 0
                            sampleByteIndex += 1
                        }
                        
                        hashBitIndex += 1
                        if hashBitIndex >= 8 {
                            hashBitIndex = 0
                            hashByteIndex += 1
                        }
                    }
                }
                
                signals[i] = Double(sample) / Double(1 << (bitPerSample - 1))
            }
        }
    }
    
    
    static func generate(frequency: Double, length: Int) -> OVBleep {
        let signals = UnsafeMutableBufferPointer<Double>.allocate(capacity: length)
        
        for i in 0 ..< length {
            signals[i] = sin(Double(i) * frequency * 2 * Double.pi / Double(length))
        }
        
        
        let bleep = OVBleep(signals: signals)
        
        return bleep
    }
}
