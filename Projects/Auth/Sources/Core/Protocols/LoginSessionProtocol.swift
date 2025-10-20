//
//  LoginSessionProtocol.swift
//  Auth
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import AuthenticationServices
import RxSwift

/// - 소셜 로그인 정보
public struct SocialLoginInfo {
    public let name: String?
    public let idToken: String

    public init(name: String?, idToken: String) {
        self.name = name
        self.idToken = idToken
    }
}

/// - 소셜 로그인 세션 Protocol
public protocol LoginSessionRepository {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginInfo>
    func getAppleLoginError() -> Observable<Error>
    func performKakaoLogin() -> Observable<SocialLoginInfo>
}
