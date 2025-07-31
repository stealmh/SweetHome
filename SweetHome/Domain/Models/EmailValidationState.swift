//
//  EmailValidationState.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

enum EmailValidationState {
    case idle             // 초기 상태
    case checking         // 검사 중
    case available        // 사용 가능 (200)
    case unavailable      // 사용 불가 (409)
    case invalid(String) // 잘못된 형식 (400)
    case error            // 네트워크 오류
    case customError(String)
    
    var message: String {
        switch self {
        case .idle:
            return ""
        case .checking:
            return "이메일을 확인하는 중입니다..."
        case .available:
            return "사용 가능한 이메일입니다"
        case .unavailable:
            return "이미 사용 중인 이메일입니다"
        case .invalid:
            return "올바르지 않은 이메일 형식입니다"
        case .error:
            return "이메일 확인 중 오류가 발생했습니다"
        case let .customError(message):
            return message
        }
    }
    
    var isValid: Bool {
        switch self {
        case .available:
            return true
        default:
            return false
        }
    }
}
