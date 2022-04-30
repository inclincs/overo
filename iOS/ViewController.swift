//
//  ViewController.swift
//  Overo
//
//  Created by cnlab on 2021/07/13.
//

import UIKit
import AVKit

import faad
import faac
import world
import wav
import embed



// 구현 계획
//
// 재생:
// Audio Player
//
// 녹음:
// Audio Recorder
// Overo Realtime Processor: AAC, WAV, Voice Transformation, Hash Embedding, File
//
// 통화:
// Bluetooth File Receiver
// Overo Realtime Processor
//
// 프라이버시 보호:
// Overo Postprocessor
//
class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var updateTimer: Timer!

    @IBOutlet var audioSlider: UISlider!
    @IBOutlet var playingTime: UILabel!
    @IBOutlet var reversePlayingTime: UILabel!
    @IBOutlet var playButton: UIButton!
    
    var audioFile: URL!
    var audioPlayer: AVAudioPlayer!
    let updateToPlayAudioSelector: Selector = #selector(updateToPlayAudio)
    
    
    @IBOutlet var recordingTime: UILabel!
    @IBOutlet var recordButton: UIButton!
    
    var recordingPermission: Bool = false
    var recordFile: URL!
    var audioRecorder: AVAudioRecorder!
    let updateToRecordAudioSelector: Selector = #selector(updateToRecordAudio)
    
    
    
    // Playing
    @IBAction func onPlayAudio(_ sender: Any) {
        if self.playButton.currentTitle == "재생" {
            self.playAudio()
            
            self.playButton.setTitle("일시정지", for: .normal)
        }
        else {
            self.pauseAudio()
            
            self.playButton.setTitle("재생", for: .normal)
        }
    }
    
    func playAudio() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                               target: self,
                                               selector: updateToPlayAudioSelector,
                                               userInfo: nil,
                                               repeats: true)
        }
        
        audioPlayer.play()
    }
    
    func pauseAudio() {
        audioPlayer.pause()
    }

    @IBAction func stopAudio(_ sender: Any) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        
        updateTimer.invalidate()
        updateTimer = nil
        
        playButton.setTitle("재생", for: .normal)
        
        updateToPlayAudio()
    }
    
    @IBAction func onTouchDownSlider(_ sender: Any) {
        audioPlayer.pause()
        
        updateTimer.invalidate()
        updateTimer = nil
    }
    
    @IBAction func onTouchUpSlider(_ sender: Any) {
        audioPlayer.currentTime = audioPlayer.duration * Double(audioSlider.value)

        updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                           target: self,
                                           selector: updateToPlayAudioSelector,
                                           userInfo: nil,
                                           repeats: true)
        
        audioPlayer.play()
    }
    
    @objc func updateToPlayAudio() {
        if audioPlayer.isPlaying == false {
            return
        }
        
        let totalTime = audioPlayer.duration
        let playingTime = audioPlayer.currentTime
        
        var minutes = Int(playingTime / 60)
        var seconds = Int(playingTime.truncatingRemainder(dividingBy: 60))
        
        self.playingTime.text = String(format: "%02d:%02d", minutes, seconds)
        
        minutes = Int((totalTime - playingTime) / 60)
        seconds = Int((totalTime - playingTime).truncatingRemainder(dividingBy: 60))
        
        self.reversePlayingTime.text = String(format: "-%02d:%02d", minutes, seconds)
        
        audioSlider.setValue(Float(playingTime / totalTime), animated: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateTimer.invalidate()
        updateTimer = nil
        
        playButton.setTitle("재생", for: .normal)
    }
    
    
    // Recording
    @IBAction func onRecordAudio(_ sender: Any) {
        if self.recordButton.currentTitle == "녹음" {
            self.startRecording()
            
            self.recordButton.setTitle("중지", for: .normal)
        }
        else {
            self.stopRecording()
            
            self.recordButton.setTitle("녹음", for: .normal)
        }
    }
    
    func startRecording() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                               target: self,
                                               selector: updateToRecordAudioSelector,
                                               userInfo: nil,
                                               repeats: true)
        }
        print("start recording")
        audioRecorder.record()
    }
    
    func stopRecording() {
        print("stop recording")
        audioRecorder.stop()
        
        updateTimer.invalidate()
        updateTimer = nil
        
        recordButton.setTitle("녹음", for: .normal)
        
        updateToRecordAudio()
    }
    
    @objc func updateToRecordAudio() {
        let currentTime = audioRecorder.currentTime
        
        let minutes = Int(currentTime / 60)
        let seconds = Int(currentTime.truncatingRemainder(dividingBy: 60))
        
        print(currentTime)
        recordingTime.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    func initialize() {
        initializePlayer()
        initializeRecorder()
        initializeUI()
    }
    
    func initializePlayer() {
//        audioFile = Bundle.main.url(forResource: "infile", withExtension: "aac")
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFile = documentDirectory.appendingPathComponent("record.aac")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
            
            audioPlayer.delegate = self
            
            audioPlayer.numberOfLoops = 0
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 3.0
            
            updateToPlayAudio()
        }
        catch let error as NSError {
            print("Error: AVAudioPlayer init ... \(error)")
        }
    }
    
    func initializeRecorder() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordFile = documentDirectory.appendingPathComponent("record.aac")
//        print(FileManager.default.fileExists(atPath: recordFile.path))
        
        let settings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
//            AVEncoderBitRateKey : 160000,
            AVNumberOfChannelsKey : 1,
            AVSampleRateKey : 16000.0
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordFile, settings: settings)
            
            audioRecorder.delegate = self
        } catch let error as NSError {
            print("Error: AVAudioRecorder init ... \(error)")
        }
        
        //AVAudioSession의 session 생성 후 , 액티브 설정
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            session.requestRecordPermission { granted in
                self.recordButton.isEnabled = granted
            }
        } catch let error as NSError {
            print(" Error-setCategory : \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print(flag)
        print("record finished")
    }
    
    func initializeUI() {
        self.audioSlider.setValue(0, animated: false)
    }
}
