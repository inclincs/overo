//
//  RecordingViewController.swift
//  Overo
//
//  Created by cnlab on 2021/08/04.
//

import Foundation
import UIKit
import AVKit
import MapKit

class RecordingViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    enum RecordingError: Error {
        case generateStorage(_ msg: String)
        case storeAudio(_ msg: String)
    }
    
    struct AudioData {
        var name: String
        var duration: Double
        var datetime: String
        var location: String?
    }
    
    var recorder: OVRecorder!
    var temporaryRecordingAudioStorage: URL?
    var recordingAudioDatetime: String?
    var recordingAudioLocation: String?
    
    var isRecording: Bool! = false
    
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()

    var locality: String?

    @IBOutlet var recordingAudioName: UITextField!
    @IBOutlet var recordingDuration: UILabel!
    @IBOutlet var recordButton: UIButton!
    
    
    @IBAction func onRecord(_ sender: Any) {
        if isRecording == false {
            record()
        }
        else if isRecording == true {
            stop()
        }
    }
    
    
    
    func record() {
        isRecording = nil
        recordButton.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let audioStorage = try? self.generateTemporaryStorage() {
                let audioData = self.generateRecordingAudioData()
                let audioFilePath = self.generateRecordingAudioFilePath(audioStorage)
                
                
                self.temporaryRecordingAudioStorage = audioStorage
                (self.recordingAudioDatetime, self.recordingAudioLocation) = audioData
                
                
                self.isRecording = true
                
                DispatchQueue.main.async {
                    self.recordButton.setTitle("중지".localized(), for: .normal)
                    self.recordButton.isEnabled = true
                    
                    
                    self.recorder.record(audioFilePath)
                }
            }
            else {
                self.isRecording = false
                DispatchQueue.main.async {
                    self.recordButton.setTitle("녹음".localized(), for: .normal)
                    self.recordButton.isEnabled = true
                }
            }
        }
    }
    
    func generateTemporaryStorage() throws -> URL {
        let randomNumber = Int.random(in: 0 ..< 10000)
        let name = "temp-\(randomNumber)"
        
        let storage: URL = OVStorage.data.appendingPathComponent(name)
        
        do {
            try OVFile.create(directory: storage)
        }
        catch {
            throw RecordingError.generateStorage("temporary audio storage")
        }
        
        // Speaker Privacy Protection 관련 Storage
        let originalAudioStorage = storage.appendingPathComponent("original") // 폰에서 직접 녹음한 오디오 파일
        let transformedAudioStorage = storage.appendingPathComponent("transformed") // Speaker Privacy Protection을 거친 변환된 오디오 파일
        
        do {
            try OVFile.create(directory: originalAudioStorage)
        }
        catch {
            try OVFile.remove(directory: storage)
            throw RecordingError.generateStorage("temporary original audio storage")
        }
        
        do {
            try OVFile.create(directory: transformedAudioStorage)
        }
        catch {
            try OVFile.remove(directory: storage)
            throw RecordingError.generateStorage("temporary transformed audio storage")
        }
        
        // Speech Privacy Protection 관련 Storage
//        let decodedAudioStorage = storage.appendingPathComponent("decoded") // Speech Privacy Protection을 거친 파일들을 들을 수 있게 만든 조립한 오디오 파일
//        let embeddedBleepSoundStorage = storage.appendingPathComponent("embedded") // Speech Privacy Protection을 거치고 나온 부산물인 Embedded Bleep Sound 파일
//        let overlappedSoundStorage = storage.appendingPathComponent("overlapped") // Speech Privacy Protection을 거쳐 나온 부산물인 MDCT-Overlapped Sound 파일
        
        return storage
    }
    
    func generateRecordingAudioData() -> (String, String?) {
        return (generateDatetime(), retrieveCurrentLocation())
    }
    
    func generateDatetime() -> String {
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let datetime: String = formatter.string(from: now)
        
        return datetime
    }
    
    func retrieveCurrentLocation() -> String? {
        return locality
    }
    
    func generateRecordingAudioFilePath(_ storage: URL) -> URL {
        return storage
            .appendingPathComponent("original")
            .appendingPathComponent("original.aac")
    }

    
    
    func stop() {
        isRecording = nil
        
        recordButton.isEnabled = false
        
        recorder.stop { duration in
            showRecordingStopMessage()
            
            if let audioStorage = temporaryRecordingAudioStorage {
                print(audioStorage) // DEBUG: OK
                if let audioId = try? storeRecordedAudio(duration) {
                    print(audioId) // DEBUG: OK
                    
                    OVRealtimeProcessing.addAudioId(audioId)
                    
                    DispatchQueue.global(qos: .utility).async {
                        do {
                            try self.realtimeProcessRecordedAudio(audioStorage, audioId)
                            self.renameDirectoryToAudioId(audioStorage, audioId)
                        }
                        catch {
                            switch error {
                            case OVRealtimeProcessor.RealtimeProcessingError.loadOriginalAudioFile:
                                self.removeRecordedAudioFromStorage(audioStorage)
                                self.removeRecordedAudioFromDatabase(audioId)
                                break
                            default:
                                break
                            }
                            print(error)
                        }
                        
                        OVRealtimeProcessing.removeAudioId(audioId)
                    }
                }
                else {
                    removeRecordedAudioFromStorage(audioStorage)
                }
            }
            

            recordingAudioDatetime = nil
            recordingAudioLocation = nil
            temporaryRecordingAudioStorage = nil
        }
        
        isRecording = false
        
        recordButton.setTitle("녹음".localized(), for: .normal)
        recordButton.isEnabled = true
    }
    
    func showRecordingStopMessage() {
        let alert = UIAlertController(title: "녹음".localized(), message: "녹음을 완료하였습니다!".localized(), preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "확인".localized(), style: .default)
        
        alert.addAction(ok)
        
        present(alert, animated: true)
    }
    
    func storeRecordedAudio(_ duration: Double) throws -> Int {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            throw RecordingError.storeAudio("database open")
        }
        
        
        let queryInsertAudio: String = """
            INSERT INTO
                Audio
                (type, name, duration, datetime, location)
            VALUES
                (?, ?, ?, ?, ?)
        """
        
        do {
            let audioName: String = recordingAudioName.text == "" ? recordingAudioName.placeholder! : recordingAudioName.text!
            let audioDuration: Double = duration
            let audioDatetime: String = recordingAudioDatetime!
            let audioLocation: String? = recordingAudioLocation
            
            try db.insert(queryInsertAudio) { context in
                context.bind(1, int: OVAudio.AudioType.Record.rawValue)
                context.bind(2, text: audioName)
                context.bind(3, double: audioDuration)
                context.bind(4, text: audioDatetime)
                context.bind(5, text: audioLocation)
            }
        }
        catch {
            print(error)
            db.close()
            throw RecordingError.storeAudio("insert audio data")
        }
        
//        // DEBUG: OK
//        do {
//            print("DEBUG: storeRecordedAudio")
//
//            let query = """
//                SELECT
//                    *
//                FROM
//                    Audio
//            """
//
//            try db.query(query) { context in
//                while context.next() {
//                    print(context.readInt(0),
//                    context.readInt(1),
//                    context.readText(2)!,
//                    context.readDouble(3),
//                    context.readText(4)!,
//                    context.readText(5)!)
//                }
//            }
//        }
//        catch {
//            print(error)
//        }
        
        
        let audioId = db.getLastInsertRowId()
        
        db.close()
        
        return audioId
    }
    
    func realtimeProcessRecordedAudio(_ storage: URL, _ audioId: Int) throws {
        let processor = OVRealtimeProcessor(storage, audioId)
        
        try processor.process()
    }
    
    func renameDirectoryToAudioId(_ storage: URL, _ audioId: Int) {
        let recordingAudioStorage = OVStorage.getStorage(audioId)
        
        if OVFile.exist(directory: recordingAudioStorage) {
            do {
                try OVFile.remove(recordingAudioStorage)
            }
            catch {
                print(error)
            }
        }
        
        do {
            try OVFile.move(at: storage, to: recordingAudioStorage)
        }
        catch {
            print(error)
        }
    }
    
    func removeRecordedAudioFromStorage(_ storage: URL) {
        try? OVFile.remove(storage)
    }
    
    func removeRecordedAudioFromDatabase(_ audioId: Int) {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
        }
        
        do {
            try db.execute("DELETE FROM Audio WHERE id=\(audioId)")
        }
        catch {
            print(error)
        }
        
        db.close()
    }
    
    
    override func viewDidLoad() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch let error as NSError {
            print(" Error ... viewDidLoad: AVAudioSession Category, Active Setting: \(error)")
        }
        
        recordingAudioName.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let session = AVAudioSession.sharedInstance()
        
        if session.recordPermission != .granted {
            session.requestRecordPermission { granted in
                if !granted {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        
        initializeOveroAudioRecorder()
    }
    
    func initializeOveroAudioRecorder() {
        recorder = OVRecorder()
        recorder.verbose = true
        recorder.updateCallback = updateCallback
    }
    
    func updateCallback(recorder: AVAudioRecorder) {
        if recorder.isRecording == false {
            return
        }
        
        let currentTime = recorder.currentTime
        
        let minutes = Int(currentTime / 60)
        let seconds = Int(currentTime.truncatingRemainder(dividingBy: 60))
        
        recordingDuration.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }

            self.locality = placemark.locality
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
        
        locality = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
