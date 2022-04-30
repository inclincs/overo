//
//  OVPlayer.swift
//  Overo
//
//  Created by cnlab on 2021/08/16.
//

import Foundation
import AVFAudio

class OVPlayer: NSObject, AVAudioPlayerDelegate {
    
    var player: AVAudioPlayer?
    
    var verbose: Bool = false
    
    var updateTimer: Timer?
    let updateToPlayAudioSelector: Selector = #selector(updateToPlayAudio)
    var updateCallback: (AVAudioPlayer) -> Void = { _ in }
    
    var finishCallback: (AVAudioPlayer) -> Void = { _ in }
    
    var isLoaded: Bool {
        get {
            return player != nil
        }
    }
    
    var duration: Double? {
        get {
            return player?.duration
        }
    }
    
    var currentTime: Double? {
        get {
            return player?.currentTime
        }
        
        set {
            if let v = newValue {
                player?.currentTime = v
            }
        }
    }
    
    init(_ filePath: URL) {
        super.init()
        
        do {
            player = try AVAudioPlayer(contentsOf: filePath)
            player?.delegate = self
        }
        catch {
            print(error)
            player = nil
        }
    }
    
    
    func setAudioFile(_ audioFilePath: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: audioFilePath)
            player?.delegate = self
        }
        catch {
            print(error)
            player = nil
        }
    }
    
    func play() {
        startUpdating()
        startPlaying()
    }
    
    func startUpdating() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                               target: self,
                                               selector: updateToPlayAudioSelector,
                                               userInfo: nil,
                                               repeats: true)
        }
    }
    
    @objc func updateToPlayAudio() {
        guard let player = player else {
            return
        }
        
        if player.isPlaying == false {
            return
        }
        
        updateCallback(player)
    }
    
    func startPlaying() {
        if let player = player {
            player.play()
        }
        else {
            stopUpdating()
        }
    }
    
    func pause() {
        stopPlaying()
        stopUpdating()
    }
    
    func stopPlaying() {
        if let player = player {
            player.pause()
        }
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            return
        }
        
        finishCallback(player)
    }
}
