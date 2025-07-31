//
//  RegisterModels.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

// MARK: - Data Models
struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}

struct RegisterResponse: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}

enum RegisterError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case emptyNickname
    case networkError(Error)
    case userAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "유효하지 않은 이메일 형식입니다."
        case .weakPassword:
            return "비밀번호는 최소 8자 이상이며, 영문자, 숫자, 특수문자를 포함해야 합니다."
        case .emptyNickname:
            return "닉네임을 입력해주세요."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .userAlreadyExists:
            return "이미 존재하는 사용자입니다."
        }
    }
}
