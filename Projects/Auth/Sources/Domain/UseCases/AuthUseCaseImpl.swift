//
//  AuthUseCaseImpl.swift
//  Auth
//
//  Created by Claude on 10/20/25.
//

import Foundation
import RxSwift
import AuthInterface

/// - AuthUseCase의 구현체
/// - 인증 관련 비즈니스 로직을 처리
public final class AuthUseCaseImpl: AuthUseCase {

    // MARK: - Dependencies
    private let repository: AuthRepository

    // MARK: - Initialization
    public init(repository: AuthRepository) {
        self.repository = repository
    }

    // MARK: - Email Authentication

    public func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        return repository.loginWithEmail(loginInfo: loginInfo)
    }

    public func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        return repository.registerWithEmail(registerInfo: registerInfo)
    }

    // MARK: - Social Authentication

    public func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        return repository.loginWithKakao(loginInfo: loginInfo)
    }

    public func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        return repository.loginWithApple(loginInfo: loginInfo)
    }

    // MARK: - Logout

    public func logout() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            self?.repository.clearTokens()
            self?.repository.saveLoginState(isLoggedIn: false)
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }

    // MARK: - Token Management

    public func refreshToken() -> Observable<AuthTokens> {
        return repository.refreshToken()
    }

    public func isLoggedIn() -> Bool {
        return repository.isLoggedIn()
    }
}
