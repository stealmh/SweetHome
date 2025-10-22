//
//  AuthRepositoryImpl.swift
//  Auth
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import AuthInterface
import CoreStorage

/// - AuthRepository의 구현체
/// - 네트워크 API와 로컬 저장소를 통합하여 인증 데이터 관리
final class AuthRepositoryImpl: AuthRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol
    private let keychainManager: KeyChainManagerProtocol

    // MARK: - Initialization
    init(
        apiClient: ApiClientProtocol,
        keychainManager: KeyChainManagerProtocol
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
    }

    // MARK: - Email Authentication

    func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        let request = AuthRequestMapper.toEmailLoginRequest(from: loginInfo)
        return apiClient.requestObservable(UserEndpoint.emailLogin(request))
            .map { AuthResponseMapper.toLoginResult(from: $0) }
            .do(onNext: { [weak self] (response: LoginResult) in
                self?.saveTokens(accessToken: response.tokens.accessToken, refreshToken: response.tokens.refreshToken)
                self?.saveUserID(response.user.userId)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        let request = AuthRequestMapper.toRegisterRequest(from: registerInfo)
        return apiClient.requestObservable(UserEndpoint.emailRegister(request))
            .map { return AuthResponseMapper.toRegisterResultFromRegisterResponse(from: $0) }
    }

    // MARK: - Social Authentication

    func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        let request = AuthRequestMapper.toKakaoLoginRequest(from: loginInfo)
        return apiClient.requestObservable(UserEndpoint.kakaoLogin(request))
            .map { AuthResponseMapper.toLoginResult(from: $0) }
            .do(onNext: { [weak self] (response: LoginResult) in
                self?.saveTokens(accessToken: response.tokens.accessToken, refreshToken: response.tokens.refreshToken)
                self?.saveUserID(response.user.userId)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        let request = AuthRequestMapper.toAppleLoginRequest(from: loginInfo)
        return apiClient.requestObservable(UserEndpoint.appleLogin(request))
            .map { AuthResponseMapper.toLoginResult(from: $0) }
            .do(onNext: { [weak self] (response: LoginResult) in
                self?.saveTokens(accessToken: response.tokens.accessToken, refreshToken: response.tokens.refreshToken)
                self?.saveUserID(response.user.userId)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    // MARK: - Token Management
    func refreshToken() -> Observable<AuthTokens> {
        guard let refreshToken = keychainManager.read(.refreshToken) else {
            return Observable.error(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Refresh token not found"]))
        }

        return apiClient.requestObservable(AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager))
            .map { return AuthResponseMapper.toAuthTokensFromReIssue(from: $0) }
            .do(onNext: { [weak self] (response: AuthTokens) in
                self?.keychainManager.save(.accessToken, value: response.accessToken)
                self?.keychainManager.save(.refreshToken, value: response.refreshToken)
            })
    }

    // MARK: - Local Storage

    public func saveLoginState(isLoggedIn: Bool) {
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
    }

    public func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    public func saveTokens(accessToken: String, refreshToken: String) {
        keychainManager.save(.accessToken, value: accessToken)
        keychainManager.save(.refreshToken, value: refreshToken)
    }

    private func saveUserID(_ userID: String) {
        keychainManager.save(.userID, value: userID)
    }

    public func clearTokens() {
        keychainManager.delete(.accessToken)
        keychainManager.delete(.refreshToken)
        keychainManager.delete(.userID)
    }
}
