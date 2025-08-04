//
//  LoginSession.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa

import RxKakaoSDKAuth
import RxKakaoSDKUser
import KakaoSDKUser
import KakaoSDKAuth
import KakaoSDKCommon

protocol LoginSessionProtocol {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginResponse>
    func getAppleLoginError() -> Observable<SHError>
    func performKakaoLogin() -> Observable<SocialLoginResponse>
}

class LoginSession: NSObject, LoginSessionProtocol {
    
    // MARK: - Private Properties
    private let appleLogin = PublishSubject<SocialLoginResponse>()
    private let appleLoginError = PublishSubject<SHError>()
    private weak var currentPresentationContext: ASAuthorizationControllerPresentationContextProviding?
    
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginResponse> {
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
    
    func getAppleLoginError() -> Observable<SHError> {
        return appleLoginError.asObservable()
    }
    
    func performKakaoLogin() -> Observable<SocialLoginResponse> {
        let loginObservable: Observable<SocialLoginResponse>
        
        if UserApi.isKakaoTalkLoginAvailable() {
            loginObservable = UserApi.shared.rx.loginWithKakaoTalk()
                .map { SocialLoginResponse(name: nil, idToken: $0.accessToken) }.asObservable()
        } else {
            loginObservable = UserApi.shared.rx.loginWithKakaoAccount()
                .map { SocialLoginResponse(name: nil, idToken: $0.accessToken) }.asObservable()
        }
        
        return loginObservable
            .catch { error -> Observable<SocialLoginResponse> in
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
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            handleAppleLoginSuccess(appleIDCredential)
        default:
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
        let appleResult = SocialLoginResponse(
            name: fullName,
            idToken: idTokenString
        )
        appleLogin.onNext(appleResult)
    }
    
    func handleAppleLoginError(_ error: Error) {
        if let authError = error as? ASAuthorizationError {
            let loginError: SHError
            switch authError.code {
            case .canceled:
                loginError = .networkError(.apple(.canceled))
            case .failed:
                loginError = .networkError(.apple(.failed))
            case .invalidResponse:
                loginError = .networkError(.apple(.invalidResponse))
            case .notHandled:
                loginError = .networkError(.apple(.notHandled))
            default:
                loginError = .networkError(.apple(.unknown))
            }
            appleLoginError.onNext(loginError)
        } else {
            appleLoginError.onNext(.networkError(.apple(.unknown)))
        }
    }
}
