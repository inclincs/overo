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
        //         lost.wav (RP: 삭제, PP: 삭제)
        //     speech/[speech privacy protection id]/
        //         data.sbi: overlap data 추출할 때 필요한 speech privacy sensitive block indices 정보(PP: 삭제)
        //         data.olp: speech privacy protection 시 생성되는 overlap data(PP: 삭제)
        //         profile.dat: verification을 할 수 있는 정보를 모아둔 metadata 파일
        //         erased.aac: playback할 수 없게 지워진 audio
        //         recovered.aac: playback할 수 있게 복구한 audio
        
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
        // Method 1: Realtime Processing 때 transform하는 부분에서 나오는 VAD를 저장해야함
        // Method 2: VAD 구하는 건 빠르니까 original audio를 열어서 다시 구하기 ... 채택
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
0        // 전제: sensitiveBlockIndices는 음수를 포함하지 않는다
        // 전제: sensitiveBlockIndices는 감소하지 않는다(오름차순으로 정렬되어있다)
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
        // 딱히 없음
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
        // transformed.aac를 speech privacy sensitive block을 지워서 erased.aac로 만듦
        // OVAACEraser.erase(lostTransformedAudioAACFilePath, erasedAudioAACFilePath, speechPrivacySensitiveBlockIndices)
    }
    
    
    func recoverSpeechPrivacyProtectedAudio() {
        // erased.aac에 overlap을 넣어서 recovered.wav로 저장
        // recovered.wav를 열어서 recoveredAudio로 만듦
        let erasedAudio = loadErasedAudioWithRecovering()
        
        // recoveredAudio에 Speech Privacy Sensitive Block에 Bleep을 넣음
        let recoveredAudio = insertBleepSoundToErasedBlock(erasedAudio: erasedAudio)
        
        // recoveredAudio를 recovered.wav로 저장 후 recovered.aac로 변환
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
        // bleep sound 생성
        // speech sensitive block에 각각 bleep sound copy해서 넣기
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
