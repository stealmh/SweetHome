//
//  LoginUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import AuthenticationServices

/// - LoginUseCase의 구현체
/// - Repository와 LoginSession을 조합하여 로그인 비즈니스 로직 구현
class LoginUseCaseImpl: LoginUseCase {

    // MARK: - Dependencies
    private let authRepository: AuthRepository
    private let loginSession: LoginSessionProtocol

    // MARK: - Initialization
    init(
        authRepository: AuthRepository = AuthRepositoryImpl(),
        loginSession: LoginSessionProtocol = LoginSession()
    ) {
        self.authRepository = authRepository
        self.loginSession = loginSession
    }

    // MARK: - Email Authentication

    func loginWithEmail(email: String, password: String) -> Observable<Void> {
        // 유효성 검사
        if let validationError = validateLoginData(email: email, password: password) {
            return Observable.error(validationError)
        }

        let deviceToken = KeyChainManager.shared.read(.fcmToken)
        let requestModel = EmailLoginRequest(
            email: email,
            password: password,
            deviceToken: deviceToken
        )

        return authRepository.loginWithEmail(request: requestModel)
            .map { _ in () }
    }

    // MARK: - Social Authentication

    func loginWithKakao() -> Observable<Void> {
        return loginSession.performKakaoLogin()
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self = self else { return Observable.empty() }

                let deviceToken = KeyChainManager.shared.read(.fcmToken) ?? ""
                let requestModel = KakaoLoginRequest(
                    oauthToken: socialLoginResponse.idToken,
                    deviceToken: deviceToken
                )

                return self.authRepository.loginWithKakao(request: requestModel)
                    .map { _ in () }
            }
    }

    func loginWithApple(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<Void> {
        return loginSession.performAppleLogin(presentationContext: presentationContext)
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self = self else { return Observable.empty() }

                let deviceToken = KeyChainManager.shared.read(.fcmToken) ?? ""
                let requestModel = AppleLoginRequest(
                    idToken: socialLoginResponse.idToken,
                    deviceToken: deviceToken,
                    nick: socialLoginResponse.name ?? ""
                )

                return self.authRepository.loginWithApple(request: requestModel)
                    .map { _ in () }
            }
    }

    func getAppleLoginError() -> Observable<SHError> {
        return loginSession.getAppleLoginError()
    }

    // MARK: - Validation

    func validateLoginData(email: String, password: String) -> SHError? {
        /// 🚨 Case [1]. 잘못된 이메일 형식
        guard email.isValidEmail else { return .clientError(.textfield(.invalidEmailFormat)) }
        /// 🚨 Case [2]. 잘못된 비밀번호 형식
        guard password.isValidPassword else { return .clientError(.textfield(.invalidEmailFormat)) }

        return nil
    }
}