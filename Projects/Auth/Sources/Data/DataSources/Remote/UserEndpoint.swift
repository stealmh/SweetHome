//
//  UserEndpoint.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import Alamofire
import CoreNetwork
import AuthInterface

enum UserEndpoint: TargetType {
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
        return Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
    }

    var path: String {
        switch self {
        case .emailRegister:
            return "/v1/users/join"
        case .emailLogin:
            return "/v1/users/login"
        case .kakaoLogin:
            return "/v1/users/login/kakao"
        case .appleLogin:
            return "/v1/users/login/apple"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .emailRegister, .emailLogin, .kakaoLogin, .appleLogin:
            return .post
        }
    }

    var task: HTTPTask {
        switch self {
        case let .emailRegister(model):
            return .requestJSONEncodable(model)
        case let .emailLogin(model):
            return .requestJSONEncodable(model)
        case let .kakaoLogin(model):
            return .requestJSONEncodable(model)
        case let .appleLogin(model):
            return .requestJSONEncodable(model)
        }
    }

    var headers: HTTPHeaders? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
        return HTTPHeaders(["SeSACKey": key])
    }
}
