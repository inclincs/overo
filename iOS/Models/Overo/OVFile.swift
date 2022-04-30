//
//  OVFile.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation

class OVFile {
    
    static func list(_ directory: URL) -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: directory.path)
        } catch {
            print("Error: \(error)")
        }
        
        return []
    }
    
    static func create(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    static func move(at: URL, to: URL) throws {
        try FileManager.default.moveItem(at: at, to: to)
    }
    
    static func remove(directory: URL) throws {
        var isDir: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir) {
            if isDir.boolValue {
                try FileManager.default.removeItem(at: directory)
            }
        }
    }
    
    static func remove(file: URL) throws {
        var isDir: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                try FileManager.default.removeItem(at: file)
            }
        }
    }
    
    static func remove(_ path: URL) throws {
        try FileManager.default.removeItem(at: path)
    }
    
    static func exist(directory: URL) -> Bool {
        var isDir: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        else {
            return false
        }
    }
    
    static func exist(file: URL) -> Bool {
        var isDir: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) {
            return !isDir.boolValue
        }
        else {
            return false
        }
    }
    
    static func exist(_ path: URL) -> Bool {
        var isDir: ObjCBool = false
        
        return FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir)
    }
}
