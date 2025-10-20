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
    /// - 푸시 토큰 업데이트
    case deviceToken(DeviceTokenRequest)
}

extension UserEndpoint {
    var baseURL: String { return APIConstants.baseURL }
    
    var path: String {
        switch self {
        case .emailValidation:
            return "/v1/users/validation/email"
        case .emailRegister:
            return "/v1/users/join"
        case .emailLogin:
            return "/v1/users/login"
        case .kakaoLogin:
            return "/v1/users/login/kakao"
        case .appleLogin:
            return "/v1/users/login/apple"
        case .deviceToken:
            return "/v1/users/deviceToken"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .emailValidation, .emailRegister, .emailLogin, .kakaoLogin, .appleLogin:
            return .post
        case .deviceToken:
            return .put
        }
    }
    
    var task: HTTPTask {
        switch self {
        case let .emailValidation(model):
            return .requestJSONEncodable(model)
        case let .emailRegister(model):
            return .requestJSONEncodable(model)
        case let .emailLogin(model):
            return .requestJSONEncodable(model)
        case let .kakaoLogin(model):
            return .requestJSONEncodable(model)
        case let .appleLogin(model):
            return .requestJSONEncodable(model)
        case let .deviceToken(model):
            return .requestJSONEncodable(model)
        }
    }
    
    var headers: HTTPHeaders? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }

        switch self {
        case .deviceToken:
            let accessToken = KeyChainManager.shared.read(.accessToken) ?? ""
            return HTTPHeaders([
                "Authorization": accessToken,
                "SeSACKey": key
            ])
        default:
            return HTTPHeaders(["SeSACKey": key])
        }
    }
}
