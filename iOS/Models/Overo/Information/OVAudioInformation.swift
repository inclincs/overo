//
//  OVAudioInformation.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation

class OVAudioInformation {
    
    // Audio에 대한 정보
    let audio: OVAudio
    
    // Speaker Privacy Protection
    // Original Audio에 대해 단 한번의 Realtime Processing에 대한 정보
    var speakerPrivacyProtection: OVSpeakerPrivacyProtection?
    
    // Speech Privacy Protection
    // 여러 번의 Postprocessing에 대한 정보
    var speechPrivacyProtections: [OVSpeechPrivacyProtection]?
    
    var protectionDegree: String {
        get {
            if speechPrivacyProtections != nil {
                return "내용 보호".localized()
            }
            else if speakerPrivacyProtection != nil {
                return "음성 보호".localized()
            }
            else {
                return "보호 안됨".localized()
            }
        }
    }
    
    init(_ audio: OVAudio) {
        self.audio = audio
    }
    
    
    func delete() {
        let audioId = audio.id
        
        deleteFromStorage(audioId)
        deleteFromDatabase(audioId)
    }
    
    func deleteFromStorage(_ audioId: Int) {
        let storage = OVStorage.getStorage(audioId)
        
        do {
            try OVFile.remove(directory: storage)
        }
        catch {
            print(error)
        }
        
//        print(OVFile.list(OVStorage.data))
    }
    
    func deleteFromDatabase(_ audioId: Int) {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
        }
        
        
        let queryDeleteAudio = """
            DELETE FROM
                Audio
            WHERE
                id=\(audioId)
        """
        
        do {
            try db.execute(queryDeleteAudio)
        }
        catch {
            print(error)
        }
        
        let queryDeleteVoiceTransformation = """
            DELETE FROM
                VoiceTransformation
            WHERE
                audio_id=\(audioId)
        """
        
        do {
            try db.execute(queryDeleteVoiceTransformation)
        }
        catch {
            print(error)
        }
        
        let queryDeleteSpeakerPrivacyProtection = """
            DELETE FROM
                SpeakerPrivacyProtection
            WHERE
                audio_id=\(audioId)
        """
        
        do {
            try db.execute(queryDeleteSpeakerPrivacyProtection)
        }
        catch {
            print(error)
        }
        
        let queryDeleteSpeechPrivacyProtection = """
            DELETE FROM
                SpeechPrivacyProtection
            WHERE
                audio_id=\(audioId)
        """
        
        do {
            try db.execute(queryDeleteSpeechPrivacyProtection)
        }
        catch {
            print(error)
        }
        
//        do {
//            try db.query("select * from Audio") { ctx in
//                while ctx.next() {
//                    print(ctx.readInt(0),
//                    ctx.readInt(1),
//                    ctx.readText(2),
//                    ctx.readDouble(3),
//                    ctx.readText(4),
//                    ctx.readText(5)
//                    )
//                }
//            }
//        }
//        catch {
//            print(error)
//        }
        
        db.close()
    }
    
    static func load(_ audioId: Int) -> OVAudioInformation? {
        guard let audio = OVAudio.load(audioId) else {
            return nil
        }
        
        
        
        let ai = OVAudioInformation(audio)
        
        if let speaker = OVSpeakerPrivacyProtection.load(audioId) {
            ai.speakerPrivacyProtection = speaker
            
            if let speeches = OVSpeechPrivacyProtection.load(audioId) {
                ai.speechPrivacyProtections = speeches
            }
        }
        
        
        
        return ai
    }
    
    static func loadAll() -> [OVAudioInformation]? {
        var result: [OVAudioInformation] = []
        
        
        
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return []
        }
        
        
        
        let queryString: String = """
            SELECT
                *
            FROM
                Audio
        """
        
        do {
            try db.query(queryString) { context in
                while context.next() {
                    let id: Int                 = context.readInt(0)
                    let type: OVAudio.AudioType = OVAudio.AudioType(rawValue: context.readInt(1))!
                    let name: String            = context.readText(2) ?? "이름 없음".localized()
                    let duration: Double        = context.readDouble(3)
                    let datetime: String        = context.readText(4) ?? "날짜 없음".localized()
                    let location: String?       = context.readText(5)
                    
                    
                    let audio: OVAudio = OVAudio(id: id, type: type)
                    
                    audio.name = name
                    audio.duration = duration
                    audio.datetime = datetime
                    audio.location = location
                    
                    
                    let ai = OVAudioInformation(audio)
                    
                    if let speaker = OVSpeakerPrivacyProtection.load(id) {
                        ai.speakerPrivacyProtection = speaker
                        
                        if let speeches = OVSpeechPrivacyProtection.load(id) {
                            ai.speechPrivacyProtections = speeches
                        }
                    }
                    
                    
                    result.append(ai)
                }
            }
        }
        catch {
            print(error)
            db.close()
            return nil
        }
        
        db.close()
        
        
        
        return result
    }
}
