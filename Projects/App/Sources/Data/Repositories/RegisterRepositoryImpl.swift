//
//  RegisterRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift
import CoreStorage
import AuthInterface

/// - RegisterRepository의 구현체
final class RegisterRepositoryImpl: RegisterRepository {

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

    // MARK: - RegisterRepository Implementation

    /// - 이메일 회원가입
    /// - Parameter registerInfo: 회원가입 정보
    /// - Returns: 회원가입 결과 (사용자 정보 + 토큰)
    func register(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        let request = AuthRequestMapper.toRegisterRequest(from: registerInfo)

        return apiClient
            .requestObservable(UserEndpoint.emailRegister(request))
            .map { AuthResponseMapper.toRegisterResultFromRegisterResponse(from: $0) }
            .do(onNext: { [weak self] (response: RegisterResult) in
                /// - 회원가입 성공 시 토큰 저장
                self?.keychainManager.save(.accessToken, value: response.tokens.accessToken)
                self?.keychainManager.save(.refreshToken, value: response.tokens.refreshToken)
            })
    }
}
