//
//  OVHash.swift
//  Overo
//
//  Created by cnlab on 2021/08/18.
//

import Foundation
import CryptoKit

class OVHash {
    
    var hasher = Insecure.SHA1()
    
    func update(_ data: Data) {
        hasher.update(data: data)
    }
    
    func finalize() -> Insecure.SHA1Digest {
        return hasher.finalize()
    }
    
    static func hash<D: DataProtocol>(_ data: D) -> Insecure.SHA1Digest {
        return Insecure.SHA1.hash(data: data)
    }
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
    
    var pointer: UnsafeMutablePointer<UInt8>? {
        var p: UnsafeMutablePointer<UInt8>!
        
        self.withUnsafeBytes { raw in
            let bound = raw.bindMemory(to: UInt8.self)
            
            p = UnsafeMutablePointer<UInt8>.allocate(capacity: bound.count)
            p.assign(from: bound.baseAddress!, count: bound.count)
        }
        
        return p
    }
}

extension Data {
    static func from(hex: String) -> Data? {
        var result: [UInt8] = []
        
        var s = hex.startIndex
        
        for _ in 0 ..< Int(hex.count / 2) {
            let e = hex.index(s, offsetBy: 2)
            
            guard let value = UInt8(hex[s ..< e], radix: 16) else {
                return nil
            }
            
            s = e
            
            result.append(value)
        }
        
        return Data(result)
    }
}

extension Array where Element == UInt8 {
    func toHex() -> String {
        return self.map { String(format: "%02X", $0) }.joined()
    }
}
