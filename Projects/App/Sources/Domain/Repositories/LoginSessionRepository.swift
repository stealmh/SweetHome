//
//  LoginSessionRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/16/25.
//

import RxSwift
import AuthenticationServices

public protocol LoginSessionRepository {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginInfo>
    func getAppleLoginError() -> Observable<SHError>
    func performKakaoLogin() -> Observable<SocialLoginInfo>
}
