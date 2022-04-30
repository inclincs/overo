//
//  Localization.swift
//  Overo
//
//  Created by cnlab on 2021/08/17.
//

import Foundation


extension String {
    
    func localized(_ comment: String="") -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    func localized(with arguments: CVarArg = [], _ comment: String="") -> String {
        return String(format: localized(comment), arguments)
    }
}
