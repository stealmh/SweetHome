//
//  SHError.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

public enum ErrorDisplayType {
    case toast
    case componentText
    case none
}

public enum SHError: Error {
    case commonError(CommonError)
    /// - 클라이언트에서 발생한 에러
    case clientError(ClientError)
    /// - 네트워크/서버를 통해 발생한 에러
    case networkError(NetworkError)
    /// - 소켓/채팅 관련 에러
    case socketError(SocketError)
    /// - 매물/지도 관련 에러
    case estateError(EstateError)
    /// - CoreData 관련 에러
    case coreDataError(CoreDataError)
    /// - 알림 관련 에러
    case notificationError(NotificationError)
    /// - 위치 관련 에러
    case locationError(LocationError)
    /// - 음성 녹음 관련 에러
    case voiceRecordingError(VoiceRecordingError)
    
    var message: String {
        switch self {
        case let .commonError(error):
            return error.message
            
        case let .clientError(.textfield(error)):
            return error.message
            
        case let .networkError(error):
            return error.message
            
        case let .socketError(error):
            return error.message
            
        case let .estateError(error):
            return error.message
            
        case let .coreDataError(error):
            return error.message
            
        case let .notificationError(error):
            return error.message
            
        case let .locationError(error):
            return error.errorDescription ?? "위치 오류가 발생했습니다."

        case let .voiceRecordingError(error):
            return error.errorDescription ?? "음성 녹음 오류가 발생했습니다."
        }
    }
    
    /// 에러를 어떤 방식으로 표시할지 결정
    var displayType: ErrorDisplayType {
        switch self {
        case .commonError(let error):
            return error.displayType
        case .clientError(let error):
            return error.displayType
        case .networkError(let error):
            return error.displayType
        case .socketError(let error):
            return error.displayType
        case .estateError(let error):
            return error.displayType
        case .coreDataError(let error):
            return error.displayType
        case .notificationError(let error):
            return error.displayType
        case .locationError(_):
            return .toast
        case .voiceRecordingError(_):
            return .toast
        }
    }
    
    /// 기존 호환성을 위한 프로퍼티
    var shouldShowToast: Bool {
        return displayType == .toast
    }
}

/// - VoiceRecordingError: 음성 녹음 관련 에러
public enum VoiceRecordingError: Error, LocalizedError {
    case permissionDenied        /// - 마이크 권한 거부
    case recordingFailed         /// - 녹음 실패
    case playbackFailed          /// - 재생 실패
    case fileNotFound            /// - 녹음 파일을 찾을 수 없음
    case invalidFormat           /// - 지원하지 않는 오디오 포맷

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "마이크 사용 권한이 필요합니다."
        case .recordingFailed:
            return "녹음에 실패했습니다."
        case .playbackFailed:
            return "재생에 실패했습니다."
        case .fileNotFound:
            return "녹음 파일을 찾을 수 없습니다."
        case .invalidFormat:
            return "지원하지 않는 오디오 포맷입니다."
        }
    }
}

public extension SHError {
    /// - Error to SHError
    static func from(_ error: Error) -> SHError {
        if let shError = error as? SHError { return shError }
        if let voiceError = error as? VoiceRecordingError { return .voiceRecordingError(voiceError) }
        return .networkError(.unknown(statusCode: nil, message: "잠시후 다시 시도해주세요."))
    }
}

