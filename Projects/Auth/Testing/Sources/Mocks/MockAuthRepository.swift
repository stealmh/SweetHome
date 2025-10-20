//
//  MockAuthRepository.swift
//  AuthTesting
//
//  Created by Claude on 10/20/25.
//

import Foundation
import RxSwift
import AuthInterface

/// - 테스트용 Mock AuthRepository
public final class MockAuthRepository: AuthRepository {

    // MARK: - Mock Data
    public var loginResult: Observable<LoginResult>?
    public var registerResult: Observable<RegisterResult>?
    public var refreshTokenResult: Observable<AuthTokens>?
    public var shouldThrowError: Error?

    // MARK: - State Tracking
    public var loginCallCount = 0
    public var registerCallCount = 0
    public var refreshTokenCallCount = 0
    public var saveTokensCallCount = 0
    public var clearTokensCallCount = 0

    public var savedIsLoggedIn: Bool = false
    public var savedAccessToken: String?
    public var savedRefreshToken: String?

    public init() {}

    // MARK: - AuthRepository Methods

    public func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        if let error = shouldThrowError {
            return Observable.error(error)
        }
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        registerCallCount += 1
        if let error = shouldThrowError {
            return Observable.error(error)
        }
        return registerResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        if let error = shouldThrowError {
            return Observable.error(error)
        }
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        if let error = shouldThrowError {
            return Observable.error(error)
        }
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func refreshToken() -> Observable<AuthTokens> {
        refreshTokenCallCount += 1
        if let error = shouldThrowError {
            return Observable.error(error)
        }
        return refreshTokenResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func saveLoginState(isLoggedIn: Bool) {
        savedIsLoggedIn = isLoggedIn
    }

    public func isLoggedIn() -> Bool {
        return savedIsLoggedIn
    }

    public func saveTokens(accessToken: String, refreshToken: String) {
        saveTokensCallCount += 1
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
    }

    public func clearTokens() {
        clearTokensCallCount += 1
        savedAccessToken = nil
        savedRefreshToken = nil
    }
}
