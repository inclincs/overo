//
//  DiarizationViewController.swift
//  Overo
//
//  Created by cnlab on 2021/08/25.
//

import Foundation
import UIKit

class DiarizationViewController: UIViewController {
    // Diarization 방식: 화자 단위
    //   화자 단위로 Diarization함
    //   디테일은 유저가 수정함
    //   화자 단위로 Voice(Speaker) Privacy 처리함
    
    // 구현
    // 1. Audio Player 구현: 음성 파일을 열어서 플레이어 인스턴스 생성
    //    OVPlayer를 사용하여 구현
    // 2. Audio Visualizer 구현: 연 음성 파일을 wav로 가져와서 signal 보여주기
    //    확대/축소 가능, 드래그로 스크롤 가능
    //    --- 요구사항: 뷰 그리기, 터치 입력
    //    AAC를 WAV로 변환, WAV를 디코드해서 Sample단위로 가져옴
    //    Sample을 View에 순서대로 출력
    //    View에 출력하는 시작위치, 끝위치로 확대/축소 구현
    // 3. Audio Visualizer에 영역 구현(X): 화자를 표시하는 영역을 표현하기
    //    영역 추가/삭제 가능, 영역을 터치하여 선택/드래그로 수정 가능
    //    --- 요구사항: 뷰 터치입력, 뷰 그리기
    //    영역을 담는 리스트를 가지고 있음
    //    View에 영역을 테두리로 표시함
    //    View에서 영역을 터치로 선택
    //    View에서 영역을 길게 눌러 삭제(경고창)
    //    View에서 영역의 왼쪽/오른쪽 끝테두리를 드래그해서 수정
    // 4. 일괄적으로 Voice Privacy 보호 기능 구현
    //    화자 목록에서 화자 단위로 보호 여부를 선택 가능
    //    --- 요구사항: 화자 목록 뷰, 여부 표시
    //    TableView로 화자 목록과 여부를 표시(TableCell)
    //    cell의 보호 여부 변경 시 db 업데이트
    // 5. Speech To Text로 단어 단위로 말한 내용 표시하기
    //    어느 화자가 무엇을 말했는지 단어 단위로 나열
    //    단어 터치 시 그 단어를 말한 화자를 왼쪽/오른쪽 화자로 변경
    //    --- 요구사항: Speech To Text, 단어 표시 레이블, 단어 레이블 터치
    //    Speech To Text 결과 가져오기
    //    레이블 만들기
    //    레이블에 STT 결과 적용
    //    터치 시 앞/뒤 화자로 변경
}
