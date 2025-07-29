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

protocol LoginSessionProtocol {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<AppleLoginResult>
    func getAppleLoginError() -> Observable<LoginError>
}

class LoginSession: NSObject, LoginSessionProtocol {
    
    // MARK: - Private Properties
    private let appleLogin = PublishSubject<AppleLoginResult>()
    private let appleLoginError = PublishSubject<LoginError>()
    private weak var currentPresentationContext: ASAuthorizationControllerPresentationContextProviding?
    
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<AppleLoginResult> {
        self.currentPresentationContext = presentationContext
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentationContext
        authorizationController.performRequests()
        
        return appleLogin.asObservable()
    }
    
    func getAppleLoginError() -> Observable<LoginError> {
        return appleLoginError.asObservable()
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
        let email = credential.email
        let identityToken = credential.identityToken
        let authorizationCode = credential.authorizationCode
        
        let appleResult = AppleLoginResult(
            email: email,
            idToken: identityToken,
            authorizationCode: authorizationCode
        )
        appleLogin.onNext(appleResult)
    }
    
    func handleAppleLoginError(_ error: Error) {
        if let authError = error as? ASAuthorizationError {
            let loginError: LoginError
            switch authError.code {
            case .canceled:
                loginError = .userCanceled
            case .failed:
                loginError = .authenticationFailed
            case .invalidResponse:
                loginError = .invalidResponse
            case .notHandled:
                loginError = .notHandled
            case .unknown:
                loginError = .unknown
            default:
                loginError = .unknown
            }
            appleLoginError.onNext(loginError)
        } else {
            appleLoginError.onNext(.networkError(error))
        }
    }
}
