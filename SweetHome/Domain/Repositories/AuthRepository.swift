//
//  AuthRepository.swift
//  SweetHome
//
//  Created by 김민호 on 9/19/25.
//

import Foundation
import RxSwift

/// - 인증 관련 데이터 접근을 추상화하는 Repository
protocol AuthRepository {
    /// - 이메일 로그인
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse>
    /// - 이메일 회원가입
    func registerWithEmail(request: RegisterRequest) -> Observable<RegisterResponse>
    /// - 카카오 로그인
    func loginWithKakao(request: KakaoLoginRequest) -> Observable<LoginResponse>
    /// - 애플 로그인
    func loginWithApple(request: AppleLoginRequest) -> Observable<LoginResponse>
    /// - 토큰 갱신
    func refreshToken() -> Observable<ReIssueResponse>
    /// - 로그인 상태 저장
    func saveLoginState(isLoggedIn: Bool)
    /// - 로그인 상태 조회
    func isLoggedIn() -> Bool
    /// - 사용자 토큰 저장
    func saveTokens(accessToken: String, refreshToken: String)
    /// - 사용자 토큰 삭제
    func clearTokens()
}
