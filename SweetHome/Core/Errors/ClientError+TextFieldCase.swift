//
//  ClientError+TextFieldCase.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

enum TextFieldCase {
    /// - 이메일 형식이 올바르지 않을 때
    case invalidEmailFormat
    /// - 비밀번호가 보안 요구사항을 충족하지 않을 때
    case weakPassword
    /// - 필수 입력 필드가 비어있을 때
    case emptyRequiredField(String)
    /// - 전화번호 형식이 올바르지 않을 때
    case invalidPhoneNumber
    /// - 닉네임이 입력되지 않았을 때
    case emptyNickname
}

extension TextFieldCase {
    var message: String {
        switch self {
        case .invalidEmailFormat:
            return "유효하지 않은 이메일 형식입니다."
        case .weakPassword:
            return "비밀번호는 최소 8자 이상이며, 영문자, 숫자, 특수문자를 포함해야 합니다."
        case .emptyRequiredField(let field):
            return "\(field)을(를) 입력해주세요."
        case .invalidPhoneNumber:
            return "올바른 전화번호 형식이 아닙니다."
        case .emptyNickname:
            return "닉네임을 입력해주세요."
        }
    }

    var displayType: ErrorDisplayType {
        return .componentText
    }
    
    /// 기존 호환성을 위한 프로퍼티
    var shouldShowToast: Bool {
        return displayType == .toast
    }
}
