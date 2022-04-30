//
//  OVConfiguration.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation
import CryptoKit

class OVConfiguration {
    
    static let BlockSize: Int = 1024
    
    static let VADThreshold: Int = -45
    static let VADWindowLength: Double = 0.005
    static let VADwindowHopSize: Double = 0.005
}
