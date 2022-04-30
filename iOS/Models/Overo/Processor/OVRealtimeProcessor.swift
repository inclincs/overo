//
//  OVRealtimeProcessor.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation
import CryptoKit

class OVRealtimeProcessing {
    
    static let queue = DispatchQueue(label: "com.wheels.Overo.RealtimeProcessing")
    static var processingIds: [Int] = []
    
    static func contains(audioId: Int) -> Bool {
        var result = false
        
        queue.sync {
            result = processingIds.contains(audioId)
        }
        
        return result
    }
    
    static func addAudioId(_ audioId: Int) {
        queue.async {
            processingIds.append(audioId)
        }
    }
    
    static func removeAudioId(_ audioId: Int) {
        queue.async {
            if let audioIdIndex = processingIds.firstIndex(of: audioId) {
                processingIds.remove(at: audioIdIndex)
            }
        }
    }
}

class OVRealtimeProcessor {
    
    enum RealtimeProcessingError: Error {
        case loadOriginalAudioFile
        case generateAudioHash
    }
    
    let hashLength: Int = Insecure.SHA1.byteCount
    let blockSize: Int = OVConfiguration.BlockSize
    
    let storage: URL
    let audioId: Int
    
    let originalAudioStorage: URL
    let speakerPrivacyProtectionStorage: URL
    
    let originalAACAudioFilePath: URL
    let originalWAVAudioFilePath: URL
    let transformedWAVAudioFilePath: URL
    let transformedAACAudioFilePath: URL
    let lostTransformedWAVAudioFilePath: URL
    
    init(_ storage: URL, _ audioId: Int) {
        self.storage = storage
        self.audioId = audioId
        
        // MARK: Storage Structure
        // data/[audio id]/ <- storage(RP: 임시 이름으로 설정되어있는 상태)
        //     original/
        //         original.aac
        //         original.wav (RP: 삭제)
        //     speaker/
        //         transformed.wav (RP: 삭제)
        //         transformed.aac
        //         lost.wav (RP: 삭제)
        //     speech/[speech privacy protection id]/
        //         profile.dat: verification을 할 수 있는 정보를 모아둔 metadata 파일
        //         erased.aac: playback할 수 없게 지워진 audio
        //         overlap.dat: speech privacy protection 시 생성되는 overlap data (미정)
        //         recovered.aac: playback할 수 있게 복구한 audio
        
        originalAudioStorage = storage.appendingPathComponent("original")
        
        originalAACAudioFilePath = originalAudioStorage.appendingPathComponent("original.aac")
        originalWAVAudioFilePath = originalAudioStorage.appendingPathComponent("original.wav")
        
        
        speakerPrivacyProtectionStorage = storage.appendingPathComponent("speaker")
        
        transformedWAVAudioFilePath = speakerPrivacyProtectionStorage.appendingPathComponent("transformed.wav")
        transformedAACAudioFilePath = speakerPrivacyProtectionStorage.appendingPathComponent("transformed.aac")
        lostTransformedWAVAudioFilePath = speakerPrivacyProtectionStorage.appendingPathComponent("lost.wav")
    }
    
    
    func process() throws {
        // 1. load original audio
        let originalAudio = try loadOriginalAudio()
        defer { originalAudio.signals.deallocate() }
        
        // 2. transform original audio by random proper warping parameters
        let voiceTransformationResult = transformOriginalAudio(audio: originalAudio) // 최신 vad로 갱신 필요, 최신 overo vt로 갱신 필요
        let transformedAudio = voiceTransformationResult.audio
        defer { transformedAudio.signals.deallocate() }
        let warpingParameters = voiceTransformationResult.warpingParameters
        
        // 3. store transformed audio
        storeTransformedAudio(audio: transformedAudio)

        // 4. load lost transformed audio
        let lostTransformedAudio = loadLostTransformedAudio()
        defer { lostTransformedAudio.signals.deallocate() }
        
        // 5. generate overo audio hash
        let audioHash: String = try generateOveroAudioHash(audio: lostTransformedAudio,
                                                           warpingParameters: warpingParameters)
        
        // 6. store audio hash in database
//        storeAudioHash(audioHash)
        
        // 7. store warping parameters in database
//        storeWarpingParameters(warpingParameters: warpingParameters)
    }
    
    
    
    func loadOriginalAudio() throws -> Audio {
        if OVFile.exist(file: originalAACAudioFilePath) == false {
            throw RealtimeProcessingError.loadOriginalAudioFile
        }
        
        AAC.decode(aacFilePath: originalAACAudioFilePath.path,
                   wavFilePath: originalWAVAudioFilePath.path)
        
        return WAV.load(originalWAVAudioFilePath.path)
    }
    
    func transformOriginalAudio(audio: Audio) -> OVVoiceTransformation.VoiceTransformationResult {
        let voiceTransformation = OVVoiceTransformation()
        
        return voiceTransformation.transform(audio: audio)
    }
    
    func storeTransformedAudio(audio: Audio) {
        WAV.save(transformedWAVAudioFilePath.path, audio)
        AAC.encode(wavFilePath: transformedWAVAudioFilePath.path,
                   aacFilePath: transformedAACAudioFilePath.path)
    }
    
    func loadLostTransformedAudio() -> Audio {
        AAC.decode(aacFilePath: transformedAACAudioFilePath.path,
                   wavFilePath: lostTransformedWAVAudioFilePath.path)
        
        return WAV.load(lostTransformedWAVAudioFilePath.path)
    }
    
    func generateOveroAudioHash(audio: Audio,
                                warpingParameters: [OVWarpingParameter],
                                hashEmbedding: Bool=false) throws -> String {
        let audioHashGenerator = OVAudioHashGenerator(audio: audio,
                                                      warpingParameters: warpingParameters,
                                                      hashEmbedding: hashEmbedding)
        defer { audioHashGenerator.dispose() }
        
        do {
            return try audioHashGenerator.hashAudio()
        }
        catch {
            throw RealtimeProcessingError.generateAudioHash
        }
    }
    
    func storeAudioHash(audioHash: String) {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return
        }
        
        let queryInsertSpeakerPrivacyProtection = """
            INSERT INTO
                SpeakerPrivacyProtection
                (audio_id, hash)
            VALUES
                (?, ?)
        """
        
        do {
            try db.insert(queryInsertSpeakerPrivacyProtection) { context in
                let audio_id: Int = audioId
                let audio_hash: String = audioHash
                
                context.bind(1, int: audio_id)
                context.bind(2, text: audio_hash)
            }
        }
        catch {
            print(error)
        }
        
//        // DEBUG: OK
//        do {
//            print("DEBUG: storeAudioHash")
//
//            let query = """
//                SELECT
//                    *
//                FROM
//                    SpeakerPrivacyProtection
//            """
//
//            try db.query(query) { context in
//                while context.next() {
//                    print(context.readInt(0),
//                    context.readInt(1),
//                    context.readText(2)!)
//                }
//            }
//        }
//        catch {
//            print(error)
//        }
        
        db.close()
    }
    
    func storeWarpingParameters(warpingParameters: [OVWarpingParameter]) {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return
        }
        
        let queryInsertVoiceTransformation = """
            INSERT INTO
                VoiceTransformation
                (audio_id, voice_transformation_id, start_index, end_index, alpha, beta)
            VALUES
                (?, ?, ?, ?, ?, ?)
        """
        // voice_transformation_id -> warping_parameter_index
        
        do {
            for i in 0 ..< warpingParameters.count {
                try db.insert(queryInsertVoiceTransformation) { context in
                    let audio_id: Int = audioId
                    
                    let parameter = warpingParameters[i]
                    
                    let start_index = parameter.startSampleIndex
                    let end_index = parameter.endSampleIndex
                    let alpha = parameter.alpha
                    let beta = parameter.beta
                    
                    context.bind(1, int: audio_id)
                    context.bind(2, int: i)
                    context.bind(3, int: start_index)
                    context.bind(4, int: end_index)
                    context.bind(5, double: alpha)
                    context.bind(6, double: beta)
                }
            }
        }
        catch {
            print(error)
        }
        
//        // DEBUG: OK
//        do {
//            print("DEBUG: storeWarpingParameters")
//
//            let query = """
//                SELECT
//                    *
//                FROM
//                    VoiceTransformation
//            """
//
//            try db.query(query) { context in
//                while context.next() {
//                    print(context.readInt(0),
//                    context.readInt(1),
//                    context.readInt(2),
//                    context.readInt(3),
//                    context.readInt(4),
//                    context.readDouble(5),
//                    context.readDouble(6))
//                }
//            }
//        }
//        catch {
//            print(error)
//        }
        
        db.close()
    }
}
