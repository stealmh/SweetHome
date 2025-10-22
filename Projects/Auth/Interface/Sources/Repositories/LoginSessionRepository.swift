//
//  LoginSessionProtocol.swift
//  Auth
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import AuthenticationServices
import RxSwift

/// - 소셜 로그인 세션 Protocol
public protocol LoginSessionRepository {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginInfo>
    func getAppleLoginError() -> Observable<Error>
    func performKakaoLogin() -> Observable<SocialLoginInfo>
}
