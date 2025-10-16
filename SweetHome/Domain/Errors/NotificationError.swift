//
//  NotificationError.swift
//  SweetHome
//
//  Created by 김민호 on 9/1/25.
//

import Foundation

enum NotificationError {
    /// - 알림 권한이 거부되었을 때
    case permissionDenied
    /// - 푸시 알림 등록이 실패했을 때
    case registrationFailed
    /// - 알림 토큰 업데이트가 실패했을 때
    case tokenUpdateFailed
    /// - 알림 데이터 파싱이 실패했을 때
    case parsingFailed
    /// - FCM 설정이 실패했을 때
    case fcmConfigurationFailed
    /// - 앱 배지 업데이트가 실패했을 때
    case badgeUpdateFailed
}

extension NotificationError {
    var message: String {
        switch self {
        case .permissionDenied:
            return "알림 권한이 거부되었습니다. 설정에서 알림을 허용해주세요."
        case .registrationFailed:
            return "푸시 알림 등록에 실패했습니다."
        case .tokenUpdateFailed:
            return "알림 토큰 업데이트에 실패했습니다."
        case .parsingFailed:
            return "알림 데이터 파싱에 실패했습니다."
        case .fcmConfigurationFailed:
            return "FCM 설정에 실패했습니다."
        case .badgeUpdateFailed:
            return "앱 배지 업데이트에 실패했습니다."
        }
    }
    
    var displayType: ErrorDisplayType {
        switch self {
        case .permissionDenied:
            return .toast
        case .registrationFailed, .tokenUpdateFailed, .fcmConfigurationFailed:
            return .toast
        case .parsingFailed, .badgeUpdateFailed:
            return .none
        }
    }
}