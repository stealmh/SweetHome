//
//  RegisterUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 회원가입 관련 비즈니스 로직을 추상화하는 UseCase
protocol RegisterUseCase {
    /// - 회원가입 데이터 유효성 검사
    /// - Parameters:
    ///   - email: 이메일
    ///   - password: 비밀번호
    ///   - nickname: 닉네임
    /// - Returns: 유효하지 않은 경우 에러 반환
    func validateRegistrationData(email: String, password: String, nickname: String) -> SHError?

    /// - 이메일 회원가입 수행
    /// - Parameter request: 회원가입 요청 데이터
    func register(request: RegisterRequest) -> Observable<RegisterResponse>
}
