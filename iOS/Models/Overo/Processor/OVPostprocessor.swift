//
//  OVPostprocessor.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation
import CryptoKit

class OVPostprocessor {
    
    enum PostprocessingError: Error {
        case loadTransformedLostAudioFile
        case loadSpeakerPrivacyProtectionParameters
    }
    
    let hashFunction: String = "SHA128"
    let blockSize: Int = OVConfiguration.BlockSize
    
    let storage: URL
    let audioId: Int
    let protectionId: Int
    let speakerPrivacySensitiveVADSegmentIndices: [Int]
    let speechPrivacyProtection: OVSpeechPrivacyProtection
    
    let originalAudioStorage: URL
    let speakerPrivacyProtectionStorage: URL
    let speechPrivacyProtectionStorage: URL
    let speechPrivacyProtectionInstanceStorage: URL
    
    let originalAudioAACFilePath: URL
    let originalAudioWAVFilePath: URL
    let lostTransformedAudioAACFilePath: URL
    let lostTransformedAudioWAVFilePath: URL
    let inverseTransformedAudioAACFilePath: URL
    let inverseTransformedAudioWAVFilePath: URL
    let erasedAudioAACFilePath: URL
    let erasedAudioWAVFilePath: URL
    let speechPrivacySensitiveBlockIndexFilePath: URL
    let overlapFilePath: URL
    let recoveredAudioWAVFilePath: URL
    let recoveredAudioAACFilePath: URL
    let profileFilePath: URL
    
    var lostTransformedAudio: Audio!
    var speechPrivacyProtectionParameters: [OVWarpingParameter]!
    var vadSegments: [Int]!
    
    init(_ storage: URL,
         _ audioId: Int,
         _ protectionId: Int,
         _ speakerPrivacySensitiveVADSegmentIndices: [Int],
         _ speechPrivacyProtection: OVSpeechPrivacyProtection) {
        self.storage = storage
        self.audioId = audioId
        self.protectionId = protectionId
        self.speakerPrivacySensitiveVADSegmentIndices = speakerPrivacySensitiveVADSegmentIndices
        self.speechPrivacyProtection = speechPrivacyProtection
        
        // MARK: Speaker Privacy Sensitive VAD Segment Indices
        // total count: vad segment count
        
        // MARK: Speech Privacy Sensitive Block Indices
        // total count: block(1024 audio samples) count
        
        // MARK: Storage Structure
        // data/[audio id]/ <- storage
        //     original/
        //         original.aac
        //     speaker/
        //         transformed.aac
        //         lost.wav (RP: ??????, PP: ??????)
        //     speech/[speech privacy protection id]/
        //         data.sbi: overlap data ????????? ??? ????????? speech privacy sensitive block indices ??????(PP: ??????)
        //         data.olp: speech privacy protection ??? ???????????? overlap data(PP: ??????)
        //         profile.dat: verification??? ??? ??? ?????? ????????? ????????? metadata ??????
        //         erased.aac: playback??? ??? ?????? ????????? audio
        //         recovered.aac: playback??? ??? ?????? ????????? audio
        
        originalAudioStorage = storage.appendingPathComponent("original")
        
        originalAudioAACFilePath = originalAudioStorage.appendingPathComponent("original.aac")
        originalAudioWAVFilePath = originalAudioStorage.appendingPathComponent("original.wav")
        
        
        speakerPrivacyProtectionStorage = storage.appendingPathComponent("speaker")
        
        lostTransformedAudioAACFilePath = speakerPrivacyProtectionStorage.appendingPathComponent("transformed.aac")
        lostTransformedAudioWAVFilePath = speakerPrivacyProtectionStorage.appendingPathComponent("lost.wav")
        
        
        speechPrivacyProtectionStorage = storage.appendingPathComponent("speech")
        speechPrivacyProtectionInstanceStorage = speechPrivacyProtectionStorage.appendingPathComponent("\(protectionId)")
        
        erasedAudioAACFilePath = speechPrivacyProtectionInstanceStorage.appendingPathComponent("erased.aac")
        erasedAudioAACFilePath = speechPrivacyProtectionInstanceStorage.appendingPathComponent("erased.wav")
        speechPrivacySensitiveBlockIndexFilePath = speechPrivacyProtectionInstanceStorage.appendingPathComponent("data.sbi")
        overlapFilePath = speechPrivacyProtectionInstanceStorage.appendingPathComponent("data.sbi")
        
        recoveredAudioWAVFilePath = speechPrivacyProtectionStorage.appendingPathComponent("recovered.wav")
        recoveredAudioAACFilePath = speechPrivacyProtectionStorage.appendingPathComponent("recovered.aac")
        
        profileFilePath = speechPrivacyProtectionInstanceStorage.appendingPathComponent("profile.dat")
    }
    
    
    func process() throws {
        try initialize() //
        
        try storeMetadata()
        
        protectSpeakerPrivacy() //
        recoverSpeakerPrivacyProtectedAudio()
        
        protectSpeechPrivacy()
        recoverSpeechPrivacyProtectedAudio()
        
        deinitialize()
    }
    
    
    func initialize() throws {
        try loadData()
        try extractOverlapData()
    }
    
    func loadData() throws {
        try loadLostTransformedAudio()
        try loadSpeakerPrivacyProtectionParameters()
        try loadVoiceActivityDetectionSegments()
    }
    
    func loadLostTransformedAudio() throws {
        if OVFile.exist(file: lostTransformedAudioWAVFilePath) == false {
            if OVFile.exist(file: lostTransformedAudioAACFilePath) == false {
                throw PostprocessingError.loadTransformedLostAudioFile
            }
            
            AAC.decode(aacFilePath: lostTransformedAudioAACFilePath.path,
                       wavFilePath: lostTransformedAudioWAVFilePath.path)
        }
        
        let audio = WAV.load(lostTransformedAudioWAVFilePath.path)
        
        
        lostTransformedAudio = audio
    }
    
    func loadSpeakerPrivacyProtectionParameters() throws {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            throw PostprocessingError.loadSpeakerPrivacyProtectionParameters
        }
        
        
        let query = """
            SELECT
                voice_transformation_id, start_index, end_index, alpha, beta
            FROM
                VoiceTransformation
            WHERE
                audio_id=\(audioId)
            ORDER BY
                voice_transformation_id
            ASC
        """
        
        var warpingParameters: [OVWarpingParameter] = []
        
        do {
            try db.query(query, { context in
                while context.next() {
                    let start_index = context.readInt(1)
                    let end_index = context.readInt(2)
                    let alpha = context.readDouble(3)
                    let beta = context.readDouble(4)
                    
                    let warpingParameter = OVWarpingParameter(startSampleIndex: start_index,
                                                              endSampleIndex: end_index,
                                                              alpha: alpha,
                                                              beta: beta)
                    
                    warpingParameters.append(warpingParameter)
                }
            })
        }
        catch {
            print(error)
            throw PostprocessingError.loadSpeakerPrivacyProtectionParameters
        }
        
        
        db.close()
        
        
        speechPrivacyProtectionParameters = warpingParameters
    }
    
    func loadVoiceActivityDetectionSegments() throws {
        // Method 1: Realtime Processing ??? transform?????? ???????????? ????????? VAD??? ???????????????
        // Method 2: VAD ????????? ??? ???????????? original audio??? ????????? ?????? ????????? ... ??????
        AAC.decode(aacFilePath: originalAudioAACFilePath.path,
                   wavFilePath: originalAudioWAVFilePath.path)
        let originalAudio: Audio = WAV.load(originalAudioWAVFilePath.path)
        
        let vad = VoiceActivityDetector(threshold: OVConfiguration.VADThreshold,
                                        windowLength: OVConfiguration.VADWindowLength,
                                        windowHopSize: OVConfiguration.VADwindowHopSize)
        vadSegments = vad.detect(audio: originalAudio)
    }
    
    func extractOverlapData() throws {
        generateSpeechPrivacySensitiveBlockIndexFile()
        generateOverlapDataFile()
        try removeSpeechPrivacySensitiveBlockIndexFile()
    }
    
    func generateSpeechPrivacySensitiveBlockIndexFile() {
        speechPrivacyProtection.store(filePath: speechPrivacySensitiveBlockIndexFilePath)
    }
    
    func generateOverlapDataFile() {
        OVOverlap.extract(aacFilePath: lostTransformedAudioAACFilePath,
                          sbiFilePath: speechPrivacySensitiveBlockIndexFilePath,
                          olpFilePath: overlapFilePath)
    }
    
    func removeSpeechPrivacySensitiveBlockIndexFile() throws {
        try OVFile.remove(file: speechPrivacySensitiveBlockIndexFilePath)
    }
    
    
    func storeMetadata() throws {
        try generateProfile()
    }
    
    func generateProfile() throws {
//        lostTransformedAudio
//        speechPrivacyProtectionParameters
//        speechPrivacySensitiveBlockIndices
        
        let audioHashGenerat00or = OVAudioHashGenerator(audio: lostTransformedAudio,
                                                        warpingParameters: speechPrivacyProtectionParameters)
        defer { audioHashGenerator.dispose() }
        
        audioHashGenerator.hashParameters()
        
        let blockCount = lostTransformedAudio.signalLength / blockSize
        

        var blocks: [OVProfile.Block] = []
        0
0        // ??????: sensitiveBlockIndices??? ????????? ???????????? ?????????
        // ??????: sensitiveBlockIndices??? ???????????? ?????????(?????????????????? ??????????????????)
 0 0      var i = 0
        var blockPointer: UnsafeMutablePointer<Double> = lostTransformedAudio.signals
        for blockIndex in 0 ..< blockCount {
            if blockIndex == speechPrivacyProtection.blockIndices[i] {
                // MARK: Speech Privacy Sensitive
                let overoBlockHashDigest = try audioHashGenerator.hashOveroBlock(blockPointer: blockPointer,
                                                                                 blockIndex: blockIndex)

                if blockIndex == blockCount-1 || blockIndex+1 < speechPrivacyProtection.blockIndices[i] {
                    // MARK: Last Speech Privacy Sensitive
                    let data: Data = Data(overoBlockHashDigest.hexStr.utf8)
                    let block = OVProfile.SpeechPrivacySensitiveBlock(type: "Last", data: data)
                    
                    blocks.append(block)
                }
                else {
                    // MARK: Speech Privacy Sensitive
                    let data: Data = Data(overoBlockHashDigest.hexStr.utf8)
                    let block = OVProfile.SpeechPrivacySensitiveBlock(type: "Normal", data: data)
                    
                    blocks.append(block)
                }
                
                i += 1
            }
            else {
                // MARK: Speaker Privacy Sensitive, Non Sensitive
                let correspondingParameterIndices: [Int] = audioHashGenerator.findCorrespondingParameters(blockIndex)
                let parameterHashDigest = try audioHashGenerator.hashCorrespondingParameterHashes(correspondingParameterIndices)
                
                let data: Data = Data(parameterHashDigest.hexStr.utf8)
                let block = OVProfile.NonSensitiveBlock(data: data)
                
                blocks.append(block)
            }
            
            blockPointer = blockPointer.advanced(by: blockSize)
        }
        
        let profile = OVProfile(hashFunction, blockCount, blocks)
//        profile.store(profileFilePath)
    }
    
//    func generateLastSpeechPrivacySensitiveBlock(_ overoBlockHash: String) -> Profile.Block {
//        let data: Data = Data(overoBlockHash.utf8)
//
//        return Profile.SpeechPrivacySensitiveBlock(type: "Last", data: data)
//    }
//
//    func generateSpeechPrivacySensitiveBlock(_ overoBlockHash: String) -> Profile.Block {
//        let data: Data = Data(overoBlockHash.utf8)
//
//        return Profile.SpeechPrivacySensitiveBlock(type: "Normal", data: data)
//    }
//
//    func generateSpeakerPrivacySensitiveBlock(_ parameterHash: String) -> Profile.Block {
//        let data: Data = Data(parameterHash.utf8)
//
//        return Profile.SpeakerPrivacySensitiveBlock(data: data)
//    }
//    func generateNonSensitiveBlock(_ parameterHash: String) -> Profile.Block {
//        let data: Data = Data(parameterHash.utf8)
//
//        return Profile.NonSensitiveBlock(data: data)
//    }
    
    
    func protectSpeakerPrivacy() {
        // ?????? ??????
    }
    
    
    func recoverSpeakerPrivacyProtectedAudio() {
        let inverseTransformedAudio = inverseTransformAudio()
        storeInverseTransformedAudio(inverseTransformedAudio: inverseTransformedAudio)
    }
    
    func inverseTransformAudio() -> Audio {
        var revealingVADSegmentIndices: [Int] = [Int](0 ..< vadSegments.count)

        for i in 0 ..< vadSegments.count {
            if speakerPrivacySensitiveVADSegmentIndices.contains(i) == false {
                revealingVADSegmentIndices.append(i)
            }
        }
        
        let voiceTransformation = OVVoiceTransformation()
//        return voiceTransformation.inverseTransform(lostTransformedAudio, vadSegments, revealingVADSegmentIndices)
        
        return nil
    }
    
    func storeInverseTransformedAudio(inverseTransformedAudio: Audio) {
        WAV.save(inverseTransformedAudioWAVFilePath.path, inverseTransformedAudio)
        AAC.encode(wavFilePath: inverseTransformedAudioWAVFilePath.path,
                   aacFilePath: inverseTransformedAudioAACFilePath.path)
    }
    
    
    func protectSpeechPrivacy() {
        eraseSpeechPrivacySensitiveBlock()
    }
    
    func eraseSpeechPrivacySensitiveBlock() {
        // transformed.aac??? speech privacy sensitive block??? ????????? erased.aac??? ??????
        // OVAACEraser.erase(lostTransformedAudioAACFilePath, erasedAudioAACFilePath, speechPrivacySensitiveBlockIndices)
    }
    
    
    func recoverSpeechPrivacyProtectedAudio() {
        // erased.aac??? overlap??? ????????? recovered.wav??? ??????
        // recovered.wav??? ????????? recoveredAudio??? ??????
        let erasedAudio = loadErasedAudioWithRecovering()
        
        // recoveredAudio??? Speech Privacy Sensitive Block??? Bleep??? ??????
        let recoveredAudio = insertBleepSoundToErasedBlock(erasedAudio: erasedAudio)
        
        // recoveredAudio??? recovered.wav??? ?????? ??? recovered.aac??? ??????
        storeRecoveredAudio(recoveredAudio: recoveredAudio)
    }
    
    func loadErasedAudioWithRecovering() -> Audio {
        AAC.decodeWithRecovering(aacFilePath: erasedAudioAACFilePath.path,
                                 wavFilePath: erasedAudioWAVFilePath.path,
                                 sbiFilePath: speechPrivacySensitiveBlockIndexFilePath.path,
                                 olpFilePath: overlapFilePath.path)
        
        return WAV.load(erasedAudioWAVFilePath.path)
    }
    
    func insertBleepSoundToErasedBlock(erasedAudio: Audio) -> Audio {
        // bleep sound ??????
        // speech sensitive block??? ?????? bleep sound copy?????? ??????
    }

    func storeRecoveredAudio(recoveredAudio: Audio) {
        WAV.save(recoveredAudioWAVFilePath.path, recoveredAudio)
        AAC.encode(wavFilePath: recoveredAudioWAVFilePath.path,
                   aacFilePath: recoveredAudioAACFilePath.path)
    }
    
    
    func deinitialize() {
        lostTransformedAudio.signals.deallocate()
        lostTransformedAudio = nil
        
        speechPrivacyProtectionParameters.removeAll()
        speechPrivacyProtectionParameters = nil
    }
}
