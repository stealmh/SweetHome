//
//  VoiceMessageData.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation

/// - VoiceMessageData: 음성 메시지 데이터 모델
/// - 음성 파일 데이터, 길이, 파일명을 포함하는 구조체
public struct VoiceMessageData {
    /// - 녹음된 음성 파일 데이터
    public let audioData: Data
    /// - 음성 길이 (초)
    public let duration: TimeInterval
    /// - 파일명 (선택적, 자동 생성 가능)
    public let fileName: String?

    public init(audioData: Data, duration: TimeInterval, fileName: String? = nil) {
        self.audioData = audioData
        self.duration = duration
        self.fileName = fileName
    }

    /// - 자동 생성된 파일명 반환
    public var generatedFileName: String {
        if let fileName = fileName {
            return fileName
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        return "voice_message_\(timestamp).mp4"
    }
}
