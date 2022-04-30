//
//  RecordingTableViewCell.swift
//  Overo
//
//  Created by cnlab on 2021/08/03.
//

import Foundation
import UIKit

class RecordingTableViewCell: UITableViewCell {
    
    @IBOutlet var name: UILabel!
    @IBOutlet var duration: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var isProtected: UILabel!
    
    private var _isEnabled: Bool = true
    
    var isEnabled: Bool {
        get {
            return _isEnabled
        }
        
        set {
            let color: UIColor = newValue ? .label : .lightGray
            
            name.textColor = color
            duration.textColor = color
            date.textColor = color
            isProtected.textColor = color
            
            isUserInteractionEnabled = newValue
            
            _isEnabled = newValue
        }
    }
}
