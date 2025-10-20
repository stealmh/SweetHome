//
//  AuthUseCase.swift
//  AuthInterface
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import RxSwift

/// - 인증 관련 비즈니스 로직을 추상화하는 UseCase
public protocol AuthUseCase {
    /// - 이메일 로그인
    /// - Parameter loginInfo: 이메일 로그인 정보
    /// - Returns: 로그인 결과
    func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult>

    /// - 이메일 회원가입
    /// - Parameter registerInfo: 회원가입 정보
    /// - Returns: 회원가입 결과
    func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult>

    /// - 카카오 로그인
    /// - Parameter loginInfo: 카카오 로그인 정보
    /// - Returns: 로그인 결과
    func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult>

    /// - 애플 로그인
    /// - Parameter loginInfo: 애플 로그인 정보
    /// - Returns: 로그인 결과
    func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult>

    /// - 로그아웃
    /// - Returns: 로그아웃 성공 여부
    func logout() -> Observable<Void>

    /// - 토큰 갱신
    /// - Returns: 갱신된 토큰
    func refreshToken() -> Observable<AuthTokens>

    /// - 로그인 상태 확인
    /// - Returns: 로그인 여부
    func isLoggedIn() -> Bool
}
