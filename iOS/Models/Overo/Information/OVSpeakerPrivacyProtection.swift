//
//  OVSpeakerPrivacyProtection.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation

class OVSpeakerPrivacyProtection {
    
    // 전체 영역을 잘라서 Voice Transformation한다.
    // VAD 단위로 Voice Transform Parameter가 존재한다.
    var hash: String
    var parameters: [OVWarpingParameter]
    
    init(_ hash: String, _ parameters: [OVWarpingParameter]) {
        self.hash = hash
        self.parameters = parameters
    }
    
    
    static func load(_ audioId: Int) -> OVSpeakerPrivacyProtection? {
        var hash: String = ""
        var parameters: [OVWarpingParameter] = []
        
        
        
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return nil
        }
        
        
        
        var isSpeakerPrivacyProtected = false
        
        let querySpeakerPrivacyProtection: String = """
            SELECT
                hash
            FROM
                SpeakerPrivacyProtection
            WHERE
                audio_id=\(audioId)
        """
        
        do {
            try db.query(querySpeakerPrivacyProtection) { context in
                while context.next() {
                    hash = context.readText(0)!
                    
                    isSpeakerPrivacyProtected = true
                }
            }
        }
        catch {
            print(error)
            db.close()
            return nil
        }
        
        
        guard isSpeakerPrivacyProtected else {
            db.close()
            return nil
        }
        
        
        
        let queryVoiceTransformation: String = """
            SELECT
                voice_transformation_id,
                start_index,
                end_index,
                alpha,
                beta
            FROM
                VoiceTransformation
            WHERE
                audio_id=\(audioId)
        """
        
        do {
            try db.query(queryVoiceTransformation) { context in
                while context.next() {
//                    let voice_transformation_id: Int = context.readInt(0)
                    let start_index: Int = context.readInt(1)
                    let end_index: Int = context.readInt(2)
                    let alpha: Double = context.readDouble(3)
                    let beta: Double = context.readDouble(4)
                    
                    let parameter: OVWarpingParameter = OVWarpingParameter(startSampleIndex: start_index,
                                                                           endSampleIndex: end_index,
                                                                           alpha: alpha,
                                                                           beta: beta)
                    
                    parameters.append(parameter)
                }
            }
        }
        catch {
            print(error)
            db.close()
            return nil
        }
        
        
        db.close()
        

        
        return OVSpeakerPrivacyProtection(hash, parameters)
    }
}
