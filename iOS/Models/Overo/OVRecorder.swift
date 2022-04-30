//
//  OVRecorder.swift
//  Overo
//
//  Created by cnlab on 2021/08/12.
//

import Foundation
import AVFAudio
import MapKit

class OVRecorder: NSObject, AVAudioRecorderDelegate {
    
    let RECORDING_SETTINGS: [String:Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVNumberOfChannelsKey: 1,
        AVSampleRateKey: 16000.0,
    ]
    
    var verbose: Bool = false
    
    var recorder: AVAudioRecorder?
    
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    
    var locality: String?
    
    var updateTimer: Timer?
    var updateToRecordAudioSelector: Selector = #selector(updateToRecordAudio)
    var updateCallback: (AVAudioRecorder) -> Void = { _ in }
    
    override init() {
        super.init()
        
        let tempAudioFilePath = OVStorage.document.appendingPathComponent("temp.aac")
        
        do {
            recorder = try AVAudioRecorder(url: tempAudioFilePath, settings: RECORDING_SETTINGS)
            recorder?.record()
            recorder?.stop()
        }
        catch {
            print("Error ... Record Temp Audio File")
        }
    }
    
    
    func record(_ audioFilePath: URL) {
        startUpdating()
        startRecording(audioFilePath)
        
        if verbose {
            print("Start Recording:", audioFilePath.path)
        }
    }
    
    func startUpdating() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                               target: self,
                                               selector: updateToRecordAudioSelector,
                                               userInfo: nil,
                                               repeats: true)
        }
    }
    
    @objc func updateToRecordAudio() {
        guard let recorder = recorder else {
            return
        }

        if recorder.isRecording == false {
            return
        }

        updateCallback(recorder)
    }
    
    func startRecording(_ audioFilePath: URL) {
        if let audioRecorder = generateAudioRecorder(audioFilePath) {
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recorder = audioRecorder
        }
        else {
            stopUpdating()
        }
    }
    
    func generateAudioRecorder(_ filePath: URL) -> AVAudioRecorder? {
        do {
            return try AVAudioRecorder(url: filePath, settings: RECORDING_SETTINGS)
        } catch let error as NSError {
            print("Error ... generateAudioRecorder: AVAudioRecorder(): \(error)")
        }
        
        return nil
    }
    
    
    func stop(completion: (Double) -> Void) {
        if let duration = recorder?.currentTime {
            if verbose {
                print("Stop Recording")
            }
            
            stopRecording()
            stopUpdating()
            
            completion(duration)
        }
    }
    
    func stopRecording() {
        if let audioRecorder = recorder {
            audioRecorder.stop()
        }
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
