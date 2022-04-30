//
//  OVOverlap.swift
//  Overo
//
//  Created by cnlab on 2021/10/19.
//

import Foundation

class OVOverlap {
    
    static func extract(aacFilePath: URL, sbiFilePath: URL, olpFilePath: URL) {
        AAC.extract(aacFilePath: aacFilePath.path, sbiFilePath: sbiFilePath.path, olpFilePath: olpFilePath.path)
    }
}
