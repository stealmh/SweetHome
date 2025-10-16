//
//  LoginUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift
import AuthenticationServices

/// - 로그인 관련 비즈니스 로직을 추상화하는 UseCase
public protocol LoginUseCase {

    // MARK: - Email Authentication

    /// - 이메일 로그인
    /// - Parameters:
    ///   - email: 이메일
    ///   - password: 비밀번호
    /// - Returns: 로그인 완료 신호
    func loginWithEmail(email: String, password: String) -> Observable<Void>

    // MARK: - Social Authentication

    /// - 카카오 로그인
    /// - Returns: 로그인 완료 신호
    func loginWithKakao() -> Observable<Void>

    /// - 애플 로그인
    /// - Parameter presentationContext: 프레젠테이션 컨텍스트
    /// - Returns: 로그인 완료 신호
    func loginWithApple(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<Void>

    /// - 애플 로그인 에러 스트림
    /// - Returns: 에러 스트림
    func getAppleLoginError() -> Observable<SHError>

    // MARK: - Validation

    /// - 로그인 데이터 유효성 검사
    /// - Parameters:
    ///   - email: 이메일
    ///   - password: 비밀번호
    /// - Returns: 에러가 있으면 SHError, 없으면 nil
    func validateLoginData(email: String, password: String) -> SHError?
}