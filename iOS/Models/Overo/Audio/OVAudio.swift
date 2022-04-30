//
//  OVAudio.swift
//  Overo
//
//  Created by cnlab on 2021/08/04.
//

import Foundation

class OVAudio {
    
    enum AudioType: Int {
        case Record = 0
        case Call
    }
    
    let id: Int
    let type: AudioType
    var name: String = ""
    var duration: Double = 0.0
    var datetime: String = ""
    var location: String?
    var hash: String?
    
    var date: String {
        get {
            let dateStartIndex: String.Index = datetime.startIndex
            let dateEndIndex: String.Index = datetime.index(dateStartIndex, offsetBy: 10)
            
            return String(datetime[..<dateEndIndex])
        }
    }
    
    var time: String {
        get {
            let dateStartIndex: String.Index = datetime.startIndex
            let dateEndIndex: String.Index = datetime.index(dateStartIndex, offsetBy: 10)
            
            return String(datetime[dateEndIndex...])
        }
    }
    
    init(id: Int, type: AudioType) {
        self.id = id
        self.type = type
    }
    
    
    func getDurationTimeFormat() -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        let timeFormat = String(format: "%02d:%02d", minutes, seconds)
        
        return timeFormat
    }
    
    
    static func load(_ audioId: Int) -> OVAudio? {
        var result: OVAudio?
        
        
        
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return nil
        }
        
        
        
        let queryAudio: String = """
            SELECT
                *
            FROM
                Audio
            WHERE
                id=\(audioId)
        """
        
        do {
            try db.query(queryAudio) { context in
                while context.next() {
                    let id: Int = context.readInt(0)
                    let type: OVAudio.AudioType = OVAudio.AudioType(rawValue: context.readInt(1))!
                    let name: String = context.readText(2) ?? "이름 없음"
                    let duration: Double = context.readDouble(3)
                    let datetime: String = context.readText(4) ?? "날짜 없음"
                    let location: String? = context.readText(5)
                    
                    let audio: OVAudio = OVAudio(id: id, type: type)
                    
                    audio.name = name
                    audio.duration = duration
                    audio.datetime = datetime
                    audio.location = location
                    
                    result = audio
                }
            }
        }
        catch {
            print(error)
        }
        
        db.close()
        
        
        
        return result
    }
}
