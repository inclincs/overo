//
//  WarpingFunction.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation


protocol WarpingFunction {
    func warp(_ audio: Audio) -> WarpingResult
}
