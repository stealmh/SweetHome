//
//  RegisterUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - RegisterUseCase의 구현체
public final class RegisterUseCaseImpl: RegisterUseCase {

    // MARK: - Dependencies
    private let repository: RegisterRepository

    // MARK: - Initialization
    public init(repository: RegisterRepository) {
        self.repository = repository
    }

    // MARK: - RegisterUseCase Implementation

    /// - 회원가입 데이터 유효성 검사
    /// - Parameters:
    ///   - email: 이메일
    ///   - password: 비밀번호
    ///   - nickname: 닉네임
    /// - Returns: 유효하지 않은 경우 에러 반환
    public func validateRegistrationData(email: String, password: String, nickname: String) -> SHError? {
        guard email.isValidEmail else {
            return .clientError(.textfield(.invalidEmailFormat))
        }
        guard password.isValidPassword else {
            return .clientError(.textfield(.weakPassword))
        }
        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .clientError(.textfield(.emptyNickname))
        }
        return nil
    }

    /// - 이메일 회원가입 수행
    /// - Parameter registerInfo: 회원가입 정보
    public func register(registerInfo: RegisterInfo) -> Observable<RegisterResult> {
        return repository.register(registerInfo: registerInfo)
    }
}
