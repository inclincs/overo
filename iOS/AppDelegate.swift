//
//  AppDelegate.swift
//  Overo
//
//  Created by cnlab on 2021/07/13.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var databaseError: Bool = false
    var storageError: Bool = false
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        reset()

        databaseError = !initializeDatabase()
        storageError = !initializeStorage()
        
//        print(OVFile.list(OVFile.document))
//        print(OVFile.list(OVFile.document.appendingPathComponent("data")))
//        print(databaseError, storageError)
        
        return true
    }
    
    func reset() {
        let path = OVStorage.document
        let files = OVFile.list(path)
        
        print(files)
        
        for file in files {
            try? OVFile.remove(path.appendingPathComponent(file))
        }
        
        print(OVFile.list(path))
    }
    
    func initializeDatabase() -> Bool {
        let db = OVDatabase()
        
        do {
            try db.open()
        }
        catch {
            print(error)
            return false
        }

        
        do {
            try db.createTable("Audio", [
                "id INTEGER PRIMARY KEY AUTOINCREMENT",
                "type INTEGER NOT NULL",
                "name TEXT NOT NULL",
                "duration REAL NOT NULL",
                "datetime TEXT NOT NULL",
                "location TEXT",
            ])
        }
        catch {
            print(error)
            return false
        }
        
        
        do {
            try db.createTable("SpeakerPrivacyProtection", [
                "id INTEGER PRIMARY KEY AUTOINCREMENT",
                "audio_id INTEGER NOT NULL",
                "hash TEXT NOT NULL",
            ])
        }
        catch {
            print(error)
            return false
        }
        
        
        do {
            try db.createTable("VoiceTransformation", [
                "id INTEGER PRIMARY KEY AUTOINCREMENT",
                "audio_id INTEGER NOT NULL",
                "voice_transformation_id INTEGER NOT NULL",
                "start_index INTEGER NOT NULL",
                "end_index INTEGER NOT NULL",
                "alpha NUMBER NOT NULL",
                "beta NUMBER NOT NULL",
            ])
        }
        catch {
            print(error)
            return false
        }
        
        
        do {
            try db.createTable("SpeechPrivacyProtection", [
                "id INTEGER PRIMARY KEY AUTOINCREMENT",
                "audio_id INTEGER NOT NULL",
                "protection_id INTEGER NOT NULL",
                "block_id INTEGER NOT NULL",
            ])
        }
        catch {
            print(error)
            return false
        }
        
        return true
    }
    
    func initializeStorage() -> Bool {
        // MARK: Storage Structure
        // data/[audio id]/
        //     original/
        //         original.aac
        //         original.wav (RP: ??????)
        //     speaker/
        //         transformed.wav (RP: ??????)
        //         transformed.aac
        //         lost.wav (RP: ??????)
        //     speech/[speech privacy protection id]/
        //         profile.dat: verification??? ??? ??? ?????? ????????? ????????? metadata ??????
        //         erased.aac: playback??? ??? ?????? ????????? audio
        //         overlap.dat: speech privacy protection ??? ???????????? overlap data (??????)
        //         recovered.aac: playback??? ??? ?????? ????????? audios
        
        
        let dataStorage = OVStorage.data
        
        
        do {
            try OVFile.create(directory: dataStorage)
            
            return true
        }
        catch {
            return false
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

