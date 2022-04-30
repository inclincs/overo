//
//  OVAudioHashGenerator.swift
//  Overo
//
//  Created by cnlab on 2021/10/12.
//

import Foundation
import CryptoKit


class OVAudioHashGenerator {

    enum AudioHashGenerationError: Error {
        case digestMemoryAllocation
        case retrieveBaseAddress
        case bleepIsNotGenerated
    }
    
    let hashLength: Int = Insecure.SHA1.byteCount
    let blockSize: Int = OVConfiguration.BlockSize
    
    let audio: Audio
    let voiceTransformParameters: [OVWarpingParameter]
    var hashEmbedding: Bool = false
    
    var parameterHashes: UnsafeMutablePointer<UInt8>!
    var bleep: OVBleep?
    
    init(audio: Audio, warpingParameters: [OVWarpingParameter], hashEmbedding: Bool=false) {
        self.audio = audio
        self.voiceTransformParameters = warpingParameters
        self.hashEmbedding = hashEmbedding
    }
    
    
    func dispose() {
        parameterHashes?.deallocate()
        parameterHashes = nil
    }
    
    func hashParameters() {
        let parameterCount = voiceTransformParameters.count
        let parameterHashes = UnsafeMutablePointer<UInt8>.allocate(capacity: parameterCount * hashLength)
        
        var parameterHashesPointer = parameterHashes

        for i in 0 ..< parameterCount {
            let parameter = voiceTransformParameters[i]
            
            let a = parameter.alpha.bitPattern
            let b = parameter.beta.bitPattern
            
            let abContainer = UnsafeMutablePointer<UInt64>.allocate(capacity: 2)
            
            abContainer[0] = a
            abContainer[1] = b
            
            abContainer.withMemoryRebound(to: UInt8.self, capacity: 16) { p in
                let buffer = UnsafeBufferPointer<UInt8>(start: p, count: 16)
                let data = Data(buffer: buffer)
                let digest = OVHash.hash(data)
                
                digest.withUnsafeBytes { raw in
                    let bound = raw.bindMemory(to: UInt8.self)
                    
                    parameterHashesPointer.assign(from: bound.baseAddress!, count: bound.count)
                }
            }
            
            parameterHashesPointer = parameterHashesPointer.advanced(by: hashLength)
        }
        
        self.parameterHashes = parameterHashes
    }
    

    func hashAudio() throws -> String {
        let overoBlockHashes = try hashOveroBlocks()
        defer { overoBlockHashes.deallocate() }
        
        
        let audioHash: String = OVHash.hash([UInt8](overoBlockHashes)).hexStr
        
        return audioHash
    }
    
    func hashOveroBlocks() throws -> UnsafeMutableBufferPointer<UInt8>  {
        let blockCount = audio.signalLength / blockSize
        
        if hashEmbedding {
            bleep = OVBleep.generate(frequency: 1000, length: blockSize)
        }
        
        defer {
            bleep?.deallocate()
            bleep = nil
        }
        
        hashParameters()
        
        let overoBlockHashContainer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: blockCount * hashLength)
        overoBlockHashContainer.initialize(repeating: 0)
        
        
        guard var overoBlockHashContainerPointer = overoBlockHashContainer.baseAddress else {
            throw AudioHashGenerationError.retrieveBaseAddress
        }
        
        var blockPointer: UnsafeMutablePointer<Double> = audio.signals
        for blockIndex in 0 ..< blockCount {
            let overoBlockHashDigest = try hashOveroBlock(blockPointer: blockPointer,
                                                          blockIndex: blockIndex)
            
            guard let overoBlockHash = overoBlockHashDigest.pointer else {
                throw AudioHashGenerationError.digestMemoryAllocation
            }
            
            overoBlockHashContainerPointer.assign(from: overoBlockHash, count: hashLength)
            overoBlockHashContainerPointer = overoBlockHashContainerPointer.advanced(by: hashLength)
            
            overoBlockHash.deallocate()
            
            
            blockPointer = blockPointer.advanced(by: blockSize)
        }
        

        return overoBlockHashContainer
    }
    
    func hashOveroBlock(blockPointer: UnsafeMutablePointer<Double>,
                        blockIndex: Int) throws -> Insecure.SHA1Digest {
        let blockHashDigest = hashBlock(blockPointer)
        
        let correspondingParameterIndices = findCorrespondingParameters(blockIndex)
        let parameterHashDigest = try hashCorrespondingParameterHashes(correspondingParameterIndices)
        
        
        let blockParameterHashDigest = try hash(blockHash: blockHashDigest,
                                                parameterHash: parameterHashDigest)
        
        if hashEmbedding, let copiedBleep = bleep?.copy() {
            defer { copiedBleep.deallocate() }
            
            try copiedBleep.embed(hash: blockParameterHashDigest)
            
            let embeddedBleep = copiedBleep
            let embeddedBleepHashDigest = hash(embeddedBleep: embeddedBleep)
            
            return embeddedBleepHashDigest
        }
        else {
            return blockParameterHashDigest
        }
    }
    
    func hashBlock(_ blockPointer: UnsafeMutablePointer<Double>) -> Insecure.SHA1Digest {
        let data = Data(bytes: blockPointer, count: 8 * blockSize)
        let digest = OVHash.hash(data)
        
        return digest
    }
    
    func findCorrespondingParameters(_ blockIndex: Int) -> [Int] {
        let startBlockSampleIndex = blockIndex * blockSize
        let endBlockSampleIndex = startBlockSampleIndex + blockSize
        
        
        var correspondingParameterIndices: [Int] = []
        
        
        for i in 0 ..< voiceTransformParameters.count {
            let parameter = voiceTransformParameters[i]
            
            let start = parameter.startSampleIndex
            let end = parameter.endSampleIndex
            
            if start >= endBlockSampleIndex {
                break
            }
            
            if end < 0 || end > startBlockSampleIndex {
                correspondingParameterIndices.append(i)
            }
        }
        
        
        return correspondingParameterIndices
    }
    
    func hashCorrespondingParameterHashes(_ correspondingParameterIndices: [Int]) throws -> Insecure.SHA1Digest {
        let correspondingParameterCount = correspondingParameterIndices.count
        let correspondingParameterHashContainer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: correspondingParameterCount * hashLength)
        defer { correspondingParameterHashContainer.deallocate() }
        
        correspondingParameterHashContainer.initialize(repeating: 0)
        
        
        guard var correspondingParameterHashContainerPointer = correspondingParameterHashContainer.baseAddress else {
            throw AudioHashGenerationError.retrieveBaseAddress
        }
        
        for correspondingParameterIndex in correspondingParameterIndices {
            let parameterHashPointer = parameterHashes.advanced(by: correspondingParameterIndex * hashLength)
            
            correspondingParameterHashContainerPointer.assign(from: parameterHashPointer, count: hashLength)
            correspondingParameterHashContainerPointer = correspondingParameterHashContainerPointer.advanced(by: hashLength)
        }
        
        
        let digest = OVHash.hash([UInt8](correspondingParameterHashContainer))
        
        return digest
    }
    
    func hash(blockHash blockHashDigest: Insecure.SHA1Digest,
              parameterHash parameterHashDigest: Insecure.SHA1Digest) throws -> Insecure.SHA1Digest {
        guard let blockHash = blockHashDigest.pointer,
              let parameterHash = parameterHashDigest.pointer else {
            throw AudioHashGenerationError.digestMemoryAllocation
        }
        
        defer {
            blockHash.deallocate()
            parameterHash.deallocate()
        }
        
        
        let blockHashCount = 1
        let parameterHashCount = 1
        let totalHashCount = blockHashCount + parameterHashCount
        
        let blockAndParameterHashContainer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: totalHashCount * hashLength)
        defer { blockAndParameterHashContainer.deallocate() }
        
        
        blockAndParameterHashContainer.initialize(repeating: 0)
        
        
        guard var blockAndParameterHashContainerPointer = blockAndParameterHashContainer.baseAddress else {
            throw AudioHashGenerationError.retrieveBaseAddress
        }
        
        // MARK: Block Hash
        blockAndParameterHashContainerPointer.assign(from: blockHash, count: hashLength)
        blockAndParameterHashContainerPointer = blockAndParameterHashContainerPointer.advanced(by: hashLength)
        
        // MARK: Parameter Hash
        blockAndParameterHashContainerPointer.assign(from: parameterHash, count: hashLength)
        
        
        let digest = OVHash.hash([UInt8](blockAndParameterHashContainer))
        
        return digest
    }
    
    func hash(embeddedBleep: OVBleep) -> Insecure.SHA1Digest {
        let data = Data(buffer: embeddedBleep.signals)
        let digest = OVHash.hash(data)
        
        return digest
    }
}
