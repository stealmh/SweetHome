//
//  AuthRequestMapper.swift
//  App
//
//  Created by 김민호 on 10/22/25.
//

import Foundation
import AuthInterface
import Auth

/// - Auth 도메인 모델을 Request DTO로 변환하는 Mapper
/// - App 모듈에서 AuthInterface(Domain)와 Auth(DTO)를 모두 import하여 매핑 수행
enum AuthRequestMapper {
    /// - EmailLoginInfo -> EmailLoginRequest
    static func toEmailLoginRequest(from loginInfo: EmailLoginInfo) -> EmailLoginRequest {
        return EmailLoginRequest(
            email: loginInfo.email,
            password: loginInfo.password,
            deviceToken: loginInfo.deviceToken
        )
    }

    /// - KakaoLoginInfo -> KakaoLoginRequest
    static func toKakaoLoginRequest(from loginInfo: KakaoLoginInfo) -> KakaoLoginRequest {
        return KakaoLoginRequest(
            oauthToken: loginInfo.oauthToken,
            deviceToken: loginInfo.deviceToken
        )
    }

    /// - AppleLoginInfo -> AppleLoginRequest
    static func toAppleLoginRequest(from loginInfo: AppleLoginInfo) -> AppleLoginRequest {
        return AppleLoginRequest(
            idToken: loginInfo.idToken,
            deviceToken: loginInfo.deviceToken,
            nick: loginInfo.nickname
        )
    }

    /// - RegisterInfo -> RegisterRequest
    static func toRegisterRequest(from registerInfo: RegisterInfo) -> RegisterRequest {
        return RegisterRequest(
            email: registerInfo.email,
            password: registerInfo.password,
            nick: registerInfo.nickname,
            phoneNum: registerInfo.phoneNumber,
            introduction: registerInfo.introduction,
            deviceToken: registerInfo.deviceToken
        )
    }
}
