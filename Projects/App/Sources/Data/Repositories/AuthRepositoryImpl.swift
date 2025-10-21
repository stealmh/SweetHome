//
//  AuthRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import CoreStorage

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

    func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        let request = EmailLoginRequest(email: loginInfo.email, password: loginInfo.password, deviceToken: loginInfo.deviceToken)
        return apiClient.requestObservable(UserEndpoint.emailLogin(request))
            .do(onNext: { [weak self] (response: LoginResponse) in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveUserID(response.user_id)
                self?.saveLoginState(isLoggedIn: true)
            })
            .map { response in
                return LoginResult(
                    user: User(
                        userId: response.user_id,
                        email: response.email,
                        nickname: response.nick,
                        profileImage: response.profileImage
                    ),
                    tokens: AuthTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                )
            }
    }

    func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        let request = RegisterRequest(
            email: registerInfo.email,
            password: registerInfo.password,
            nick: registerInfo.nickname,
            phoneNum: registerInfo.phoneNumber,
            introduction: registerInfo.introduction,
            deviceToken: registerInfo.deviceToken
        )
        return apiClient.requestObservable(UserEndpoint.emailRegister(request))
            .map { (response: RegisterResponse) in
                return RegisterResult(
                    user: User(
                        userId: response.user_id,
                        email: response.email,
                        nickname: response.nick
                    ),
                    tokens: AuthTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                )
            }
    }

    // MARK: - Social Authentication

    func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        let request = KakaoLoginRequest(oauthToken: loginInfo.oauthToken, deviceToken: loginInfo.deviceToken)
        return apiClient.requestObservable(UserEndpoint.kakaoLogin(request))
            .do(onNext: { [weak self] (response: LoginResponse) in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveUserID(response.user_id)
                self?.saveLoginState(isLoggedIn: true)
            })
            .map { response in
                return LoginResult(
                    user: User(
                        userId: response.user_id,
                        email: response.email,
                        nickname: response.nick,
                        profileImage: response.profileImage
                    ),
                    tokens: AuthTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                )
            }
    }

    func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        let request = AppleLoginRequest(idToken: loginInfo.idToken, deviceToken: loginInfo.deviceToken, nick: loginInfo.nickname)
        return apiClient.requestObservable(UserEndpoint.appleLogin(request))
            .do(onNext: { [weak self] (response: LoginResponse) in
                self?.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
                self?.saveUserID(response.user_id)
                self?.saveLoginState(isLoggedIn: true)
            })
            .map { response in
                return LoginResult(
                    user: User(
                        userId: response.user_id,
                        email: response.email,
                        nickname: response.nick,
                        profileImage: response.profileImage
                    ),
                    tokens: AuthTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                )
            }
    }

    // MARK: - Token Management

    func refreshToken() -> Observable<AuthTokens> {
        guard let refreshToken = keychainManager.read(.refreshToken) else {
            return Observable.error(SHError.networkError(.refreshTokenExpired))
        }

        return apiClient.requestObservable(AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager))
            .do(onNext: { [weak self] (response: ReIssueResponse) in
                self?.keychainManager.save(.accessToken, value: response.accessToken)
                self?.keychainManager.save(.refreshToken, value: response.refreshToken)
            })
            .map { response in
                return AuthTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
            }
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

    func saveUserID(_ userID: String) {
        keychainManager.save(.userID, value: userID)
    }

    func clearTokens() {
        keychainManager.delete(.accessToken)
        keychainManager.delete(.refreshToken)
        keychainManager.delete(.userID)
    }
}