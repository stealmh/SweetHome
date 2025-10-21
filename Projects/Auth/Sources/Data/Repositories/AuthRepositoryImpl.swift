//
//  AuthRepositoryImpl.swift
//  Auth
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import AuthInterface
import CoreNetwork
import CoreStorage

/// - AuthRepository의 구현체
/// - 네트워크 API와 로컬 저장소를 통합하여 인증 데이터 관리
public final class AuthRepositoryImpl: AuthRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol
    private let keychainManager: KeyChainManagerProtocol

    // MARK: - Initialization
    public init(
        apiClient: ApiClientProtocol,
        keychainManager: KeyChainManagerProtocol
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
    }

    // MARK: - Email Authentication

    public func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult> {
        let request = EmailLoginRequest(
            email: loginInfo.email,
            password: loginInfo.password,
            deviceToken: loginInfo.deviceToken
        )
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

    public func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
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

    public func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult> {
        let request = KakaoLoginRequest(
            oauthToken: loginInfo.oauthToken,
            deviceToken: loginInfo.deviceToken
        )
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

    public func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult> {
        let request = AppleLoginRequest(
            idToken: loginInfo.idToken,
            deviceToken: loginInfo.deviceToken,
            nick: loginInfo.nickname
        )
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

    public func refreshToken() -> Observable<AuthTokens> {
        guard let refreshToken = keychainManager.read(.refreshToken) else {
            return Observable.error(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Refresh token not found"]))
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
