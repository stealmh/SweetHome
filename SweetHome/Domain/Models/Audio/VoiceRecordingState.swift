//
//  VoiceRecordingState.swift
//  SweetHome
//
//  Created by 김민호 on 9/27/25.
//

import Foundation

enum VoiceRecordingState: Equatable {
    /// - 대기 상태 (녹음 시작 전)
    case idle
    /// - 녹음 중 (경과 시간 포함)
    case recording(duration: TimeInterval)
    /// - 녹음 완료 (총 녹음 시간 포함)
    case completed(duration: TimeInterval)
    /// - 재생 중
    case playing(currentTime: TimeInterval, totalDuration: TimeInterval)
    /// - 일시정지됨 (현재 시간과 총 시간 포함)
    case paused(currentTime: TimeInterval, totalDuration: TimeInterval)

    /// - 현재 상태가 녹음 중인지 확인
    var isRecording: Bool {
        switch self {
        case .recording:
            return true
        default:
            return false
        }
    }

    /// - 현재 상태가 재생 중인지 확인
    var isPlaying: Bool {
        switch self {
        case .playing:
            return true
        default:
            return false
        }
    }

    /// - 현재 상태가 일시정지 중인지 확인
    var isPaused: Bool {
        switch self {
        case .paused:
            return true
        default:
            return false
        }
    }

    /// - 녹음이 완료되었는지 확인
    var isCompleted: Bool {
        switch self {
        case .completed, .playing, .paused:
            return true
        default:
            return false
        }
    }

    /// - 현재 시간을 반환 (녹음 중이거나 재생 중일 때)
    var currentTime: TimeInterval {
        switch self {
        case .recording(let duration):
            return duration
        case .completed(let duration):
            return duration
        case .playing(let currentTime, _):
            return currentTime
        case .paused(let currentTime, _):
            return currentTime
        default:
            return 0
        }
    }

    /// - 총 녹음 시간을 반환 (완료된 상태일 때)
    var totalDuration: TimeInterval? {
        switch self {
        case .completed(let duration):
            return duration
        case .playing(_, let totalDuration):
            return totalDuration
        case .paused(_, let totalDuration):
            return totalDuration
        default:
            return nil
        }
    }
}


/// - 웨이브폼 표시용 모델
struct AudioLevel: Equatable {
    /// - 시간
    let timestamp: TimeInterval
    /// - 오디오 레벨 (0.0 ~ 1.0)
    let level: Float

    init(timestamp: TimeInterval, level: Float) {
        self.timestamp = timestamp
        self.level = max(0.0, min(1.0, level))
    }
}
