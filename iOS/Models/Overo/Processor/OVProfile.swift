//
//  OVProfile.swift
//  Overo
//
//  Created by cnlab on 2021/10/13.
//

import Foundation

protocol OVProfileDataUnit {
    func read(fileHandle: FileHandle) throws
    func write(fileHandle: FileHandle) throws
}

class OVProfile {
    
    class Meta: OVProfileDataUnit {
        
        let type: String
        let data: Data
        
        init(type: String, data: Data) {
            self.type = type
            self.data = data
        }
        
        func read(fileHandle: FileHandle) throws {
            
        }
        
        func write(fileHandle: FileHandle) throws {
            try fileHandle.write(contentsOf: data)
        }
    }
    
    class Block: OVProfileDataUnit {
        
        let data: Data
        
        init(data: Data) {
            self.data = data
        }
        
        func read(fileHandle: FileHandle) throws {
        }
        
        func write(fileHandle: FileHandle) throws {
        }
    }
    
    class NonSensitiveBlock: Block {
        // 복원 시 VoiceTransformParameter 필요: Inverse Voice Transformation
        // 검증 시 ParameterHash 필요: BlockHash(생성 가능) + ParameterHash => OveroBlockHash 생성
    }
    
    class SpeakerPrivacySensitiveBlock: Block {
        // 검증 시 ParameterHash 필요: BlockHash(생성 가능) + ParameterHash => OveroBlockHash 생성
    }
    
    class SpeechPrivacySensitiveBlock: Block {
        // 검증 시 OveroBlockHash 필요
        let type: String
        
        init(type: String, data: Data) {
            self.type = type
            
            super.init(data: data)
        }
        
        override func write(fileHandle: FileHandle) throws {
            try fileHandle.write(contentsOf: data)
        }
    }
    
    var hashFunction: String
    var blockCount: Int
    var blocks: [Block]
    
    init(_ hashFunction: String, _ blockCount: Int, _ blocks: [Block]) {
        self.hashFunction = hashFunction
        self.blockCount = blockCount
        self.blocks = blocks
    }
    
    
    func store(_ filePath: URL) {
        do {
            try hashFunction.write(to: filePath, atomically: false, encoding: .utf8)
            
            let fileHandle = try FileHandle(forWritingTo: filePath)
            try fileHandle.seekToEnd()
            
            try withUnsafeBytes(of: UInt32(blockCount)) { p in
                try Meta(type: "Block Count", data: Data(p)).write(fileHandle: fileHandle)
            }
            
            for i in 0 ..< blocks.count {
                let block = blocks[i]
                
                try block.write(fileHandle: fileHandle)
            }
            
            try fileHandle.close()
        }
        catch {
            print(error)
        }
    }
}
