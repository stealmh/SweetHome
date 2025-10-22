//
//  AuthResponseMapper.swift
//  App
//
//  Created by 김민호 on 10/22/25.
//

import Foundation
import AuthInterface
import Auth

/// - Auth Response DTO를 도메인 모델로 변환하는 Mapper
/// - App 모듈에서 AuthInterface(Domain)와 Auth(DTO)를 모두 import하여 매핑 수행
enum AuthResponseMapper {
    /// - LoginResponse -> LoginResult
    static func toLoginResult(from response: LoginResponse) -> LoginResult {
        let user = User(
            userId: response.user_id,
            email: response.email,
            nickname: response.nick,
            profileImage: response.profileImage,
            phoneNumber: nil,
            introduction: nil
        )

        let tokens = AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return LoginResult(user: user, tokens: tokens)
    }

    /// - LoginResponse -> RegisterResult
    static func toRegisterResult(from response: LoginResponse) -> RegisterResult {
        let user = User(
            userId: response.user_id,
            email: response.email,
            nickname: response.nick,
            profileImage: response.profileImage,
            phoneNumber: nil,
            introduction: nil
        )

        let tokens = AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return RegisterResult(user: user, tokens: tokens)
    }

    /// - LoginResponse -> AuthTokens (토큰 갱신용)
    static func toAuthTokens(from response: LoginResponse) -> AuthTokens {
        return AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    /// - RegisterResponse -> RegisterResult
    static func toRegisterResultFromRegisterResponse(from response: RegisterResponse) -> RegisterResult {
        let user = User(
            userId: response.user_id,
            email: response.email,
            nickname: response.nick,
            profileImage: nil,
            phoneNumber: nil,
            introduction: nil
        )

        let tokens = AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return RegisterResult(user: user, tokens: tokens)
    }

    /// - ReIssueResponse -> AuthTokens
    static func toAuthTokensFromReIssue(from response: ReIssueResponse) -> AuthTokens {
        return AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }
}
