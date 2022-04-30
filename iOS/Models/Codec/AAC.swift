//
//  AAC.swift
//  Overo
//
//  Created by cnlab on 2021/07/22.
//

import Foundation
import faac
import faad



class AAC {
    
    static func encode(wavFilePath: String, aacFilePath: String) {
        let args: [NSString] = [
            "faac",
            wavFilePath as NSString,
            "--mpeg-vers",
            "2",
            "--no-tns",
            "--joint",
            "0",
            "-I",
            "0,-1",
            "--pns",
            "0",
            "--shortctl",
            "1",
            "-o",
            aacFilePath as NSString,
        ]
        
        let argc = args.count
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: argc)
        defer { argv.deallocate() }
        
        for i in 0 ..< argc {
            let s = args[i].utf8String
            argv[i] = UnsafeMutablePointer<CChar>(mutating: s)
        }
        defer {
            for i in 0 ..< argc {
                argv[i]?.deallocate()
            }
        }
        
        
        // faac output.wav --mpeg-vers 2 --no-tns --joint 0 -I 0,1 --pns 0 --shortctl 1 -o encoded.aac
        faac.AACEncode(Int32(argc), argv)
    }
    
    static func decode(aacFilePath: String, wavFilePath: String) {
        let args: [NSString] = [
            "faad",
            "-o",
            wavFilePath as NSString,
            aacFilePath as NSString
        ]

        let argc = args.count
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: argc)
        defer { argv.deallocate() }

        for i in 0 ..< argc {
            let s = args[i].utf8String
            argv[i] = UnsafeMutablePointer<CChar>(mutating: s)
        }
        defer {
            for i in 0 ..< argc {
                argv[i]?.deallocate()
            }
        }
        
        
        // faad -o output.wav input.aac
        faad.AACDecode(Int32(argc), argv)
    }
    
    static func extract(aacFilePath: String, sbiFilePath: String, olpFilePath: String) {
        let args: [NSString] = [
            "faad",
            "-w",
            aacFilePath as NSString,
            "--overo-extract",
            sbiFilePath as NSString,
            olpFilePath as NSString
        ]

        let argc = args.count
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: argc)
        defer { argv.deallocate() }

        for i in 0 ..< argc {
            let s = args[i].utf8String
            argv[i] = UnsafeMutablePointer<CChar>(mutating: s)
        }
        
        defer {
            for i in 0 ..< argc {
                argv[i]?.deallocate()
            }
        }
        
        
        // faad -w input.aac --overo-extract sbiFilePath.sbi olpFilePath.olp
        faad.AACDecode(Int32(argc), argv)
    }
    
    static func decodeWithRecovering(aacFilePath: String, wavFilePath: String, sbiFilePath: String, olpFilePath: String) {
        let args: [NSString] = [
            "faad",
            aacFilePath as NSString,
            "-o",
            wavFilePath as NSString,
            "--overo-insert",
            sbiFilePath as NSString,
            olpFilePath as NSString
        ]

        let argc = args.count
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: argc)
        defer { argv.deallocate() }

        for i in 0 ..< argc {
            let s = args[i].utf8String
            argv[i] = UnsafeMutablePointer<CChar>(mutating: s)
        }
        
        defer {
            for i in 0 ..< argc {
                argv[i]?.deallocate()
            }
        }
        
        
        // faad input.aac -o output.wav --overo-insert sbiFilePath.sbi olpFilePath.olp
        faad.AACDecode(Int32(argc), argv)
    }
}
