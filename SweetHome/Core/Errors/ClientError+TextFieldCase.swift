//
//  ClientError+TextFieldCase.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

enum TextFieldCase {
    /// - 잘못된 이메일 형식
    case invalidEmailFormat
    /// - 비밀번호 형식에 맞지 않음
    case weakPassword
    /// - 빈 필드 값
    case emptyRequiredField(String)
    /// - 잘못된 전화번호 형식
    case invalidPhoneNumber
    /// - 닉네임 필드가 비어있음
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
