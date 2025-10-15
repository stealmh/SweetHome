//
//  RegisterRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

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
    /// - Parameter request: 회원가입 요청 데이터
    func register(request: RegisterRequest) -> Observable<RegisterResponse> {
        return apiClient
            .requestObservable(UserEndpoint.emailRegister(request))
            .do(onNext: { [weak self] response in
                /// - 회원가입 성공 시 토큰 저장
                self?.keychainManager.save(.accessToken, value: response.accessToken)
                self?.keychainManager.save(.refreshToken, value: response.refreshToken)
            })
    }
}
