//
//  AuthRepository.swift
//  AuthInterface
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import RxSwift

/// - 인증 관련 데이터 접근을 추상화하는 Repository
public protocol AuthRepository {
    /// - 이메일 로그인
    /// - Parameter loginInfo: 이메일 로그인 정보
    /// - Returns: 로그인 결과 (사용자 정보 + 토큰)
    func loginWithEmail(loginInfo: EmailLoginInfo) -> Observable<LoginResult>

    /// - 이메일 회원가입
    /// - Parameter registerInfo: 회원가입 정보
    /// - Returns: 회원가입 결과 (사용자 정보 + 토큰)
    func registerWithEmail(registerInfo: RegisterInfo) -> Observable<RegisterResult>

    /// - 카카오 로그인
    /// - Parameter loginInfo: 카카오 로그인 정보
    /// - Returns: 로그인 결과 (사용자 정보 + 토큰)
    func loginWithKakao(loginInfo: KakaoLoginInfo) -> Observable<LoginResult>

    /// - 애플 로그인
    /// - Parameter loginInfo: 애플 로그인 정보
    /// - Returns: 로그인 결과 (사용자 정보 + 토큰)
    func loginWithApple(loginInfo: AppleLoginInfo) -> Observable<LoginResult>

    /// - 토큰 갱신
    /// - Returns: 인증 토큰 (액세스 토큰 + 리프레시 토큰)
    func refreshToken() -> Observable<AuthTokens>

    /// - 로그인 상태 저장
    func saveLoginState(isLoggedIn: Bool)

    /// - 로그인 상태 조회
    func isLoggedIn() -> Bool

    /// - 사용자 토큰 저장
    func saveTokens(accessToken: String, refreshToken: String)

    /// - 사용자 토큰 삭제
    func clearTokens()
}
