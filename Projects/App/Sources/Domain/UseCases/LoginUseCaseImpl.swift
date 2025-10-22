//
//  LoginUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import AuthenticationServices
import CoreStorage
import AuthInterface
import Auth

/// - LoginUseCase의 구현체
/// - Repository와 LoginSession을 조합하여 로그인 비즈니스 로직 구현
public class LoginUseCaseImpl: LoginUseCase {

    // MARK: - Dependencies
    private let authRepository: AuthRepository
    private let loginSession: LoginSessionRepository

    // MARK: - Initialization
    public init(
        authRepository: AuthRepository,
        loginSession: LoginSessionRepository
    ) {
        self.authRepository = authRepository
        self.loginSession = loginSession
    }

    // MARK: - Email Authentication

    public func loginWithEmail(email: String, password: String) -> Observable<Void> {
        // 유효성 검사
        if let validationError = validateLoginData(email: email, password: password) {
            return Observable.error(validationError)
        }

        let requestModel = EmailLoginInfo(
            email: email,
            password: password,
            deviceToken: nil
        )

        return authRepository.loginWithEmail(loginInfo: requestModel)
            .map { _ in () }
    }

    // MARK: - Social Authentication

    public func loginWithKakao() -> Observable<Void> {
        return loginSession.performKakaoLogin()
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self = self else { return Observable.empty() }

                let requestModel = KakaoLoginInfo(
                    oauthToken: socialLoginResponse.idToken,
                    deviceToken: nil
                )

                return self.authRepository.loginWithKakao(loginInfo: requestModel)
                    .map { _ in () }
            }
    }

    public func loginWithApple(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<Void> {
        return loginSession.performAppleLogin(presentationContext: presentationContext)
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self = self else { return Observable.empty() }

                let requestModel = AppleLoginInfo(
                    idToken: socialLoginResponse.idToken,
                    nickname: socialLoginResponse.name ?? "",
                    deviceToken: nil,
                )

                return self.authRepository.loginWithApple(loginInfo: requestModel)
                    .map { _ in () }
            }
    }

    public func getAppleLoginError() -> Observable<SHError> {
        return loginSession.getAppleLoginError()
            .map { error -> SHError in
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .canceled:
                        return .networkError(.apple(.canceled))
                    case .failed:
                        return .networkError(.apple(.failed))
                    case .invalidResponse:
                        return .networkError(.apple(.invalidResponse))
                    case .notHandled:
                        return .networkError(.apple(.notHandled))
                    default:
                        return .networkError(.apple(.unknown))
                    }
                } else {
                    return .networkError(.apple(.unknown))
                }
            }
    }

    // MARK: - Validation

    public func validateLoginData(email: String, password: String) -> SHError? {
        /// 🚨 Case [1]. 잘못된 이메일 형식
        guard email.isValidEmail else { return .clientError(.textfield(.invalidEmailFormat)) }
        /// 🚨 Case [2]. 잘못된 비밀번호 형식
        guard password.isValidPassword else { return .clientError(.textfield(.invalidEmailFormat)) }

        return nil
    }
}
