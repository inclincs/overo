//
//  Binarization.swift
//  Overo
//
//  Created by cnlab on 2021/08/10.
//

import Foundation

class Binarization {
    
    static func binarize(_ value: Double) -> [UInt8] {
        let bitPattern = value.bitPattern;
        
        return (0 ..< 8).map {
            UInt8((bitPattern >> ($0 * 8)) & 0xFF)
        }
    }
    
    static func binarize(_ value: [Double]) -> [UInt8] {
        return value.flatMap { binarize($0) }
    }
    
    static func toDouble(_ value: [UInt8]) -> [Double]? {
        guard value.count % 8 == 0 else {
            return nil
        }
        
        var result: [Double] = []
        
        for i in 0 ..< value.count / 8 {
            var l: UInt64 = 0
            
            for j in 0 ..< 8 {
                l += UInt64(value[i * 8 + j] << (j * 8))
            }
            
            result.append(Double(bitPattern: l))
        }
        
        return result
    }
    
    static func toLong(_ value: [UInt8]) -> [Int64]? {
        guard value.count % 8 == 0 else {
            return nil
        }
        
        var result: [Int64] = []
        
        for i in 0 ..< value.count / 8 {
            var l: UInt64 = 0
            
            for j in 0 ..< 8 {
                l += UInt64(value[i * 8 + j] << (j * 8))
            }
            
            result.append(Int64(bitPattern: l))
        }
        
        return result
    }
}
