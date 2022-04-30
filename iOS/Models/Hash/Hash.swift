//
//  Hash.swift
//  Overo
//
//  Created by cnlab on 2021/08/06.
//

import Foundation
import CryptoKit

enum HashError: Error {
    case convertHexToHash
}

class Hash {
    
    var value: [UInt8]
    
    init(_ value: [UInt8]) {
        self.value = value
    }
    
    func toHex() -> String {
        return value.map { String(format: "%02x", $0) }.joined()
    }
    
    static func fromHex(_ hex: String) throws -> Hash {
        var result: [UInt8] = []
        
        var s = hex.startIndex
        
        for _ in 0 ..< Int(hex.count / 2) {
            let e = hex.index(s, offsetBy: 2)
            
            guard let value = UInt8(hex[s ..< e], radix: 16) else {
                throw HashError.convertHexToHash
            }
            
            s = e
            
            result.append(value)
        }
        
        return Hash(result)
    }
    
    static func hash(_ bytes: [UInt8]) -> Hash {
        let digest: SHA256Digest = SHA256.hash(data: bytes)
        let value: [UInt8] = digest.map { $0 }
        
        return Hash(value)
    }
    
    static func hash(_ hash: Hash) -> Hash {
        let digest: SHA256Digest = SHA256.hash(data: hash.value)
        let value: [UInt8] = digest.map { $0 }
        
        return Hash(value)
    }
    
    static func hash(_ hashes: [Hash]) -> Hash {
        var hasher = SHA256()
        
        for i in 0 ..< hashes.count {
            hasher.update(data: hashes[i].value)
        }
        
        let digest = hasher.finalize()
        let value = digest.map { $0 }
        
        return Hash(value)
    }
}
