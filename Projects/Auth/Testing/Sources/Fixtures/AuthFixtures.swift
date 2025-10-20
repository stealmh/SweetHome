//
//  AuthFixtures.swift
//  AuthTesting
//
//  Created by Claude on 10/20/25.
//

import Foundation
import AuthInterface

/// - 테스트용 Fixture 데이터
public enum AuthFixtures {

    // MARK: - User Fixtures

    public static let user1 = User(
        userId: "user-001",
        email: "test@example.com",
        nickname: "테스트유저",
        profileImage: "https://example.com/profile.jpg",
        phoneNumber: "010-1234-5678",
        introduction: "안녕하세요"
    )

    public static let user2 = User(
        userId: "user-002",
        email: "kakao@example.com",
        nickname: "카카오유저",
        profileImage: nil
    )

    // MARK: - Auth Tokens Fixtures

    public static let tokens1 = AuthTokens(
        accessToken: "mock-access-token-123",
        refreshToken: "mock-refresh-token-456"
    )

    public static let tokens2 = AuthTokens(
        accessToken: "mock-access-token-789",
        refreshToken: "mock-refresh-token-012"
    )

    // MARK: - Login Result Fixtures

    public static let loginResult1 = LoginResult(
        user: user1,
        tokens: tokens1
    )

    public static let loginResult2 = LoginResult(
        user: user2,
        tokens: tokens2
    )

    // MARK: - Register Result Fixtures

    public static let registerResult1 = RegisterResult(
        user: user1,
        tokens: tokens1
    )

    // MARK: - Login Info Fixtures

    public static let emailLoginInfo = EmailLoginInfo(
        email: "test@example.com",
        password: "password123"
    )

    public static let kakaoLoginInfo = KakaoLoginInfo(
        oauthToken: "kakao-token-123"
    )

    public static let appleLoginInfo = AppleLoginInfo(
        idToken: "apple-id-token-123",
        nickname: "애플유저"
    )

    public static let registerInfo = RegisterInfo(
        email: "new@example.com",
        password: "password123",
        nickname: "신규유저"
    )
}
