//
//  ElapsedTime.swift
//  Overo
//
//  Created by cnlab on 2021/08/17.
//

import Foundation


class ElapsedTime {
    
    static var comment: String!
    static var startTime: CFAbsoluteTime!
    
    static func begin(_ comment: String) {
        self.comment = comment
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    static func end() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if let com = comment {
            print("\(com): \(elapsed)")
        }
    }
    
    static func measure(_ comment: String, with: () -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        with()
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("\(comment): \(elapsed)")
    }
}
