//
//  OVStorage.swift
//  Overo
//
//  Created by cnlab on 2021/08/04.
//

import Foundation

class OVStorage {
    
    static let shared: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.wheels.Overo")
    
    static let document: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let data: URL = document.appendingPathComponent("data")
    
    static func getStorage(_ audioId: Int) -> URL {
        return data.appendingPathComponent(String(audioId))
    }
    
    static func getOriginalAudioStorage(_ audioId: Int) -> URL {
        return getStorage(audioId).appendingPathComponent("original")
    }
    
    static func getTransformedAudioStorage(_ audioId: Int) -> URL {
        return getStorage(audioId).appendingPathComponent("transformed")
    }
    
    static func getEmbeddedBleepSoundStorage(_ audioId: Int) -> URL {
        return getStorage(audioId).appendingPathComponent("embedded")
    }
    
    static func getMDCTOverlappedSoundStorage(_ audioId: Int) -> URL {
        return getStorage(audioId).appendingPathComponent("overlapped")
    }
}
