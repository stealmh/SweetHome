//
//  AuthModels.swift
//  AuthInterface
//
//  Created by 김민호 on 10/20/25.
//

import Foundation

// MARK: - Auth Domain Models

/// - 로그인 결과
public struct LoginResult {
    public let user: User
    public let tokens: AuthTokens

    public init(user: User, tokens: AuthTokens) {
        self.user = user
        self.tokens = tokens
    }
}

/// - 회원가입 결과
public struct RegisterResult {
    public let user: User
    public let tokens: AuthTokens

    public init(user: User, tokens: AuthTokens) {
        self.user = user
        self.tokens = tokens
    }
}

/// - 인증 토큰
public struct AuthTokens {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// - 사용자 정보
public struct User {
    public let userId: String
    public let email: String
    public let nickname: String
    public let profileImage: String?
    public let phoneNumber: String?
    public let introduction: String?

    public init(
        userId: String,
        email: String,
        nickname: String,
        profileImage: String? = nil,
        phoneNumber: String? = nil,
        introduction: String? = nil
    ) {
        self.userId = userId
        self.email = email
        self.nickname = nickname
        self.profileImage = profileImage
        self.phoneNumber = phoneNumber
        self.introduction = introduction
    }
}

/// - 회원가입 정보
public struct RegisterInfo {
    public let email: String
    public let password: String
    public let nickname: String
    public let phoneNumber: String?
    public let introduction: String?
    public let deviceToken: String?

    public init(
        email: String,
        password: String,
        nickname: String,
        phoneNumber: String? = nil,
        introduction: String? = nil,
        deviceToken: String? = nil
    ) {
        self.email = email
        self.password = password
        self.nickname = nickname
        self.phoneNumber = phoneNumber
        self.introduction = introduction
        self.deviceToken = deviceToken
    }
}

/// - 이메일 로그인 정보
public struct EmailLoginInfo {
    public let email: String
    public let password: String
    public let deviceToken: String?

    public init(
        email: String,
        password: String,
        deviceToken: String? = nil
    ) {
        self.email = email
        self.password = password
        self.deviceToken = deviceToken
    }
}

/// - 카카오 로그인 정보
public struct KakaoLoginInfo {
    public let oauthToken: String
    public let deviceToken: String?

    public init(
        oauthToken: String,
        deviceToken: String? = nil
    ) {
        self.oauthToken = oauthToken
        self.deviceToken = deviceToken
    }
}

/// - 애플 로그인 정보
public struct AppleLoginInfo {
    public let idToken: String
    public let nickname: String
    public let deviceToken: String?

    public init(
        idToken: String,
        nickname: String,
        deviceToken: String? = nil
    ) {
        self.idToken = idToken
        self.nickname = nickname
        self.deviceToken = deviceToken
    }
}

/// - 소셜 로그인 정보 (내부 사용)
public struct SocialLoginInfo {
    public let name: String?
    public let idToken: String

    public init(name: String?, idToken: String) {
        self.name = name
        self.idToken = idToken
    }
}
