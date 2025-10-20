//
//  MockAuthUseCase.swift
//  AuthTesting
//
//  Created by Claude on 10/20/25.
//

import Foundation
import RxSwift
import AuthInterface

/// - 테스트용 Mock AuthUseCase
public final class MockAuthUseCase: AuthUseCase {

    // MARK: - Mock Data
    public var loginResult: Observable<LoginResult>?
    public var registerResult: Observable<RegisterResult>?
    public var refreshTokenResult: Observable<AuthTokens>?
    public var logoutResult: Observable<Void>?
    public var isLoggedInValue: Bool = false

    // MARK: - State Tracking
    public var loginCallCount = 0
    public var registerCallCount = 0
    public var logoutCallCount = 0
    public var refreshTokenCallCount = 0
    public var isLoggedInCallCount = 0

    public init() {}

    // MARK: - AuthUseCase Methods

    public func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        registerCallCount += 1
        return registerResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        loginCallCount += 1
        return loginResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func logout() -> Observable<Void> {
        logoutCallCount += 1
        return logoutResult ?? Observable.just(())
    }

    public func refreshToken() -> Observable<AuthTokens> {
        refreshTokenCallCount += 1
        return refreshTokenResult ?? Observable.error(NSError(domain: "Mock", code: -1))
    }

    public func isLoggedIn() -> Bool {
        isLoggedInCallCount += 1
        return isLoggedInValue
    }
}
