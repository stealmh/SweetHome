//
//  UserEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import Alamofire

enum UserEndpoint: TargetType {
    /// - 이메일 유효성 체크
    case emailValidation(EmailValidationRequest)
    /// - 회원가입
    case emailRegister(RegisterRequest)
    /// - 로그인
    case emailLogin(EmailLoginRequest)
    /// - 카카오 로그인
    case kakaoLogin(KakaoLoginRequest)
    /// - 애플 로그인
    case appleLogin(AppleLoginRequest)
}

extension UserEndpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else { return "" }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .emailValidation:
            return "users/validation/email"
        case .emailRegister:
            return "users/join"
        case .emailLogin:
            return "users/login"
        case .kakaoLogin:
            return "users/login/kakao"
        case .appleLogin:
            return "users/login/apple"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .emailValidation, .emailRegister, .emailLogin, .kakaoLogin, .appleLogin:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case let .emailValidation(model):
            return model
        case let .emailRegister(model):
            return model
        case let .emailLogin(model):
            return model
        case let .kakaoLogin(model):
            return model
        case let .appleLogin(model):
            return model
        }
    }
    
    var headers: [String : String]? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else {
            return ["Content-Type": "application/json"]
        }
        return [
            "SeSACKey": key
        ]
    }
}
