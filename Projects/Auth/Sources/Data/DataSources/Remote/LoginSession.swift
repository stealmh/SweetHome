//
//  LoginSession.swift
//  Auth
//
//  Created by 김민호 on 7/28/25.
//

import Foundation
import AuthenticationServices
import AuthInterface
import RxSwift
import RxCocoa

import RxKakaoSDKUser
import KakaoSDKUser
import KakaoSDKCommon

public final class LoginSession: NSObject, LoginSessionRepository {

    // MARK: - Private Properties
    private let appleLogin = PublishSubject<SocialLoginInfo>()
    private let appleLoginError = PublishSubject<Error>()
    private weak var currentPresentationContext: ASAuthorizationControllerPresentationContextProviding?

    // MARK: - Initialization
    public override init() {
        super.init()
    }

    // MARK: - Apple Login

    public func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginInfo> {
        self.currentPresentationContext = presentationContext

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentationContext
        authorizationController.performRequests()

        return appleLogin.asObservable()
    }

    public func getAppleLoginError() -> Observable<Error> {
        return appleLoginError.asObservable()
    }

    // MARK: - Kakao Login

    public func performKakaoLogin() -> Observable<SocialLoginInfo> {
        let loginObservable: Observable<SocialLoginInfo>

        if UserApi.isKakaoTalkLoginAvailable() {
            loginObservable = UserApi.shared.rx.loginWithKakaoTalk()
                .map { SocialLoginInfo(name: nil, idToken: $0.accessToken) }.asObservable()
        } else {
            loginObservable = UserApi.shared.rx.loginWithKakaoAccount()
                .map { SocialLoginInfo(name: nil, idToken: $0.accessToken) }.asObservable()
        }

        return loginObservable
            .catch { error -> Observable<SocialLoginInfo> in
                // 사용자 취소는 에러로 처리하지 않고 빈 스트림 반환
                if let sdkError = error as? SdkError, case .ClientFailed = sdkError {
                    return Observable.empty()
                }

                return Observable.error(error)
            }
    }
}

//MARK: - ASAuthorizationController Delegate
extension LoginSession: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            handleAppleLoginSuccess(appleIDCredential)
        default:
            break
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleAppleLoginError(error)
    }
}

//MARK: - Login Result Handling
private extension LoginSession {
    func handleAppleLoginSuccess(_ credential: ASAuthorizationAppleIDCredential) {
        guard let name = credential.fullName,
              let idToken = credential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else { return }

        let fullName = (name.familyName ?? "") + (name.givenName ?? "")
        let appleResult = SocialLoginInfo(
            name: fullName,
            idToken: idTokenString
        )
        appleLogin.onNext(appleResult)
    }

    func handleAppleLoginError(_ error: Error) {
        appleLoginError.onNext(error)
    }
}
