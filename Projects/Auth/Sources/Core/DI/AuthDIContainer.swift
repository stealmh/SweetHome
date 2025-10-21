//
//  AuthDIContainer.swift
//  Auth
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import RxSwift
import AuthInterface
import CoreNetwork
import CoreStorage

/// - Auth 모듈의 DI 컨테이너
/// - 외부에서 주입받은 의존성을 기반으로 Auth 모듈의 객체들을 생성
public final class AuthDIContainer {

    // MARK: - External Dependencies
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

    // MARK: - Factory Methods

    /// - AuthUseCase 생성
    public func makeAuthUseCase() -> AuthUseCase {
        let repository = makeAuthRepository()
        return AuthUseCaseImpl(repository: repository)
    }

    /// - AuthRepository 생성 (private)
    private func makeAuthRepository() -> AuthRepository {
        return AuthRepositoryImpl(
            apiClient: apiClient,
            keychainManager: keychainManager
        )
    }

    /// - AuthRepository 생성 (public - 필요시)
//    public func makeAuthRepository() -> AuthRepository {
//        return AuthRepositoryImpl(
//            apiClient: apiClient,
//            keychainManager: keychainManager
//        )
//    }
}
