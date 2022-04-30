//
//  OVSpeechPrivacyProtection.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation

class OVSpeechPrivacyProtection {
    
    let blockIndices: [Int]
    let blockRanges: [(Int, Int)] // [start, end)
    
    init(_ blockIndices: [Int]) {
        self.blockIndices = blockIndices
        
        var br: [(Int, Int)] = []
        
        var start = blockIndices[0]
        var end = start + 1
        for i in 1 ..< blockIndices.count {
            let idx = blockIndices[i]
            
            if end < idx {
                br.append((start, end))
                
                start = idx
                end = idx + 1
            }
            else {
                end += 1
            }
        }
        
        blockRanges = br
    }
    
    func store(filePath: URL) {
        
    }
    
    
    static func load(_ audioId: Int) -> [OVSpeechPrivacyProtection]? {
        var result: [OVSpeechPrivacyProtection] = []
        
        
        
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return nil
        }
        
        
        
        var isSpeechPrivacyProtected = false
        
        let queryString: String = """
            SELECT
                protection_id,
                block_id
            FROM
                SpeechPrivacyProtection
            WHERE
                audio_id=\(audioId)
            ORDER BY
                protection_id
            ASC
        """
        
        do {
            try db.query(queryString) { context in
                // 과정 검증 필요
                var protectionId: Int = 0
                var blockIndices: [Int] = []
                
                while context.next() {
                    let protection_id: Int = context.readInt(0)
                
                    if protectionId != protection_id {
                        protectionId = protection_id
                        
                        let speech = OVSpeechPrivacyProtection(blockIndices)
                        
                        result.append(speech)
                        
                        blockIndices = []
                    }
                    
                    let block_id = context.readInt(1)
                    
                    blockIndices.append(block_id)
                    
                    isSpeechPrivacyProtected = true
                }
                
                guard isSpeechPrivacyProtected else {
                    return
                }
                
                let speech = OVSpeechPrivacyProtection(blockIndices)
                
                result.append(speech)
            }
        }
        catch {
            print(error)
            db.close()
            return nil
        }
        
        db.close()
        
        
        
        return result.count > 0 ? result : nil
    }
}
