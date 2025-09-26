//
//  AuthRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift

/// - AuthRepository의 구현체
/// - 네트워크 API와 로컬 저장소를 통합하여 인증 데이터 관리
class AuthRepositoryImpl: AuthRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol
    private let keychainManager: KeyChainManagerProtocol

    // MARK: - Initialization
    init(
        apiClient: ApiClientProtocol = ApiClient.shared,
        keychainManager: KeyChainManagerProtocol = KeyChainManager.shared
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
    }

    // MARK: - Email Authentication

    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse> {
        return apiClient.requestObservable(UserEndpoint.emailLogin(request))
            .do(onNext: { [weak self] response in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    func registerWithEmail(request: RegisterRequest) -> Observable<RegisterResponse> {
        return apiClient.requestObservable(UserEndpoint.emailRegister(request))
    }

    // MARK: - Social Authentication

    func loginWithKakao(request: KakaoLoginRequest) -> Observable<LoginResponse> {
        return apiClient.requestObservable(UserEndpoint.kakaoLogin(request))
            .do(onNext: { [weak self] response in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    func loginWithApple(request: AppleLoginRequest) -> Observable<LoginResponse> {
        return apiClient.requestObservable(UserEndpoint.appleLogin(request))
            .do(onNext: { [weak self] response in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveLoginState(isLoggedIn: true)
            })
    }

    // MARK: - Token Management

    func refreshToken() -> Observable<ReIssueResponse> {
        guard let refreshToken = keychainManager.read(.refreshToken) else {
            return Observable.error(SHError.networkError(.refreshTokenExpired))
        }

        return apiClient.requestObservable(AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager))
            .do(onNext: { [weak self] (response: ReIssueResponse) in
                self?.keychainManager.save(.accessToken, value: response.accessToken)
                self?.keychainManager.save(.refreshToken, value: response.refreshToken)
            })
    }

    // MARK: - Local Storage

    func saveLoginState(isLoggedIn: Bool) {
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
    }

    func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        keychainManager.save(.accessToken, value: accessToken)
        keychainManager.save(.refreshToken, value: refreshToken)
    }

    func clearTokens() {
        keychainManager.delete(.accessToken)
        keychainManager.delete(.refreshToken)
        keychainManager.delete(.userID)
    }
}