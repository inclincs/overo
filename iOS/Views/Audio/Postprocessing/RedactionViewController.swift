//
//  RedactionViewController.swift
//  Overo
//
//  Created by cnlab on 2021/08/25.
//

import Foundation
import UIKit

class RedactionViewController: UIViewController {
    // Redaction 방식: 블럭 단위 작업, 단어 단위 작업[, 화자 단위 작업]
    //     블럭 단위 작업: 1024 sample 단위로 편집할 수 있는 뷰를 만들어서 유저가 직접 드래그해서 범위 설정할 수 있게 제공
    //     단어 단위 작업: 단어 보여주고 클릭 시 해당 단어 만큼의 범위를 설정할 수 있게 제공
    //     화자 단위 작업: 화자를 보여주고 선택 시 화자가 말한 모든 블럭을 설정할 수 있게 제공
    
    // Redaction Apply 버튼 클릭 시
    //     sensitive block indices 추출
    //     speech privacy protection을 위한 storage 생성
    //         sbi를 db에 저장해서 SpeechPrivacyProtection Table의 protection_id 가져오기
    //         protection_id로 data/[audio id]/speech/[protection id]/ 폴더 생성
    //     audio storage: data/[audio id] -> storage
    //     postprocessor.process(storage, audioId, protectionId, indices)
}
