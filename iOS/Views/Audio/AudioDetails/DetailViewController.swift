//
//  DetailViewController.swift
//  Overo
//
//  Created by cnlab on 2021/08/04.
//

import Foundation
import UIKit
import AVKit

class DetailViewController: UIViewController, AVAudioPlayerDelegate {
    
    var audioInformation: OVAudioInformation?
    
    var player: OVPlayer!
    
    var isPlaying: Bool! = false
    
    private var refreshControl = UIRefreshControl()
    
    @IBOutlet var audioName: UILabel!
    
    @IBOutlet var playingSlider: UISlider!
    @IBOutlet var playingTime: UILabel!
    @IBOutlet var reversePlayingTime: UILabel!
    @IBOutlet var playButton: UIButton!
    
    @IBOutlet var voiceTransformSwitch: UISwitch!
    
    @IBOutlet var audioDuration: UILabel!
    @IBOutlet var audioDatetime: UILabel!
    @IBOutlet var audioProtected: UILabel!
    @IBOutlet var audioHash: UILabel!
    
    
    @IBAction func onTouchDownSlider(_ sender: Any) {
        if let player = player, isPlaying == true {
            player.pause()
        }
    }
    
    @IBAction func onTouchUpSlider(_ sender: Any) {
        if let player = player {
            player.currentTime = (player.duration)! * Double(playingSlider.value)
            
            if isPlaying == true {
                player.play()
            }
        }
    }
    
    @IBAction func onPlayAudio(_ sender: Any) {
        if isPlaying == false {
            play()
        }
        else if isPlaying == true {
            pause()
        }
    }
    
    func play() {
        isPlaying = nil
        
        playButton.isEnabled = false
        voiceTransformSwitch.isEnabled = false
        
        if player.isLoaded {
            player.play()
            
            isPlaying = true
            
            playButton.setTitle("일시정지".localized(), for: .normal)
            playButton.isEnabled = true
        }
        else {
            isPlaying = false
            
            playButton.setTitle("재생".localized(), for: .normal)
            playButton.isEnabled = true
            voiceTransformSwitch.isEnabled = true
        }
    }
    
    func pause() {
        isPlaying = nil
        
        playButton.isEnabled = false
        voiceTransformSwitch.isEnabled = false
        
        
        player.pause()
        
        
        isPlaying = false
        
        playButton.setTitle("재생".localized(), for: .normal)
        playButton.isEnabled = true
        voiceTransformSwitch.isEnabled = true
    }
    
    @IBAction func onValueChanged(_ sender: Any) {
        if let ai = audioInformation {
            let audioId: Int = ai.audio.id
            let filePath: URL = voiceTransformSwitch.isOn
                ? OVStorage.getTransformedAudioStorage(audioId).appendingPathComponent("transformed.aac")
                : OVStorage.getOriginalAudioStorage(audioId).appendingPathComponent("original.aac")
            
            initializeOveroAudioPlayer(filePath)
        }
    }
    
    
    override func viewDidLoad() {
        
    }
    override func viewWillAppear(_ animated: Bool) {
        showAudioInformation()
    }
    
    func showAudioInformation() {
        if let ai = audioInformation {
            // UserDefaults로 저장한 변조 여부 불러오기
//            voiceTransformSwitch.setOn(UserDefaults, animated: false)
            
            let audioId: Int = ai.audio.id
            let filePath: URL = voiceTransformSwitch.isOn
                ? OVStorage.getTransformedAudioStorage(audioId).appendingPathComponent("transformed.aac")
                : OVStorage.getOriginalAudioStorage(audioId).appendingPathComponent("original.aac")
            
            
            initializeOveroAudioPlayer(filePath)
            
            audioName.text = ai.audio.name
            
            playingSlider.setValue(0.0, animated: false)
            
            playingTime.text = "00:00"
            
            if let duration = player.duration {
                reversePlayingTime.text = "-" + getStringTimeFormat(duration)
            }
            
            audioDuration.text = ai.audio.getDurationTimeFormat()
            audioDatetime.text = ai.audio.datetime
            audioProtected.text = ai.protectionDegree
            
            if let hash = ai.speakerPrivacyProtection?.hash.uppercased() {
                let startIndex = hash.startIndex
                let halfIndex = hash.index(startIndex, offsetBy: hash.count / 2)
                
                audioHash.text = hash[..<halfIndex] + "\n" + hash[halfIndex...]
            }
            else {
                audioHash.text = "없음".localized()
            }
        }
    }
    
    func getStringTimeFormat(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func initializeOveroAudioPlayer(_ filePath: URL) {
        player = OVPlayer(filePath)
        player.verbose = true
        player.updateCallback = updateCallback
        player.finishCallback = finishCallback
    }
    
    func updateCallback(_ player: AVAudioPlayer) {
        let totalTime = player.duration
        let currentTime = player.currentTime

        playingTime.text = getStringTimeFormat(currentTime)
        reversePlayingTime.text = "-" + getStringTimeFormat(totalTime - currentTime)

        playingSlider.setValue(Float(currentTime / totalTime), animated: true)
    }
    
    func finishCallback(_ player: AVAudioPlayer) {
        isPlaying = false
        
        playButton.setTitle("재생".localized(), for: .normal)
        playButton.isEnabled = true
        voiceTransformSwitch.isEnabled = true
    }
}
