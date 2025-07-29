//
//  LoginModels.swift
//  SweetHome
//
//  Created by 김민호 on 7/29/25.
//

import Foundation

// MARK: - Login Result
enum LoginResult {
    case email(token: String)
    case apple(SocialLoginResponse)
    case kakao(SocialLoginResponse)
}

// MARK: - Login Error
enum LoginError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case userCanceled
    case authenticationFailed
    case invalidResponse
    case notHandled
    case unknown
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .userCanceled:
            return "사용자가 로그인을 취소했습니다."
        case .authenticationFailed:
            return "인증에 실패했습니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .notHandled:
            return "처리되지 않은 오류입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .notImplemented:
            return "아직 구현되지 않은 기능입니다."
        }
    }
}