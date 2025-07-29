//
//  LoginViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa

class LoginViewModel: BaseViewModel {
    
    struct Input {
        let onAppear: Observable<Void>
        let emailLoginTapped: Observable<(email: String, password: String)>
        let registerTapped: Observable<Void>
        let appleLoginTapped: Observable<ASAuthorizationControllerPresentationContextProviding>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let loginError: Driver<LoginError>
        let shouldNavigateToMain: Driver<Void>
        let shouldNavigateToRegister: Driver<Void>
        let shouldHideSplash: Driver<Void>
    }
    
    // MARK: - Private Properties
    private let isLoadingRelay = BehaviorSubject<Bool>(value: false)
    private let loginErrorRelay = PublishSubject<LoginError>()
    private let shouldNavigateToMainRelay = PublishSubject<Void>()
    private let shouldNavigateToRegisterRelay = PublishSubject<Void>()
    private let shouldHideSplashRelay = PublishSubject<Void>()
    
    // MARK: - Dependencies
    private let loginSession: LoginSessionProtocol
    // TODO: login service
    // private let loginService: LoginServiceProtocol
    
    // MARK: - Initialization
    init(loginSession: LoginSessionProtocol = LoginSession()) {
        self.loginSession = loginSession
        super.init()
    }
    
    func transform(input: Input) -> Output {
        /// - 앱 시작 시 스플래시 및 로그인 상태 확인
        input.onAppear
            .delay(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                //TODO: 로그인 API & 키체인 값 검증
                let isLoggedIn = self?.isUserLoggedIn() ?? false
                if isLoggedIn {
                    self?.shouldNavigateToMainRelay.onNext(())
                } else {
                    self?.shouldHideSplashRelay.onNext(())
                }
            })
            .disposed(by: disposeBag)
        
        /// - 이메일 로그인
        input.emailLoginTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, credentials in
                owner.loginWithEmail(email: credentials.email, password: credentials.password)
            })
            .disposed(by: disposeBag)
        
        /// - 회원가입 이동
        input.registerTapped
            .bind(to: shouldNavigateToRegisterRelay)
            .disposed(by: disposeBag)
        
        /// - 애플 로그인
        input.appleLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, presentationContext -> Observable<AppleLoginResult> in
                owner.isLoadingRelay.onNext(true)
                return owner.loginSession.performAppleLogin(presentationContext: presentationContext)
            }
            .subscribe(onNext: { [weak self] appleResult in
                self?.processAppleLogin(appleResult)
            })
            .disposed(by: disposeBag)
        
        /// - 애플 로그인 에러
        loginSession.getAppleLoginError()
            .subscribe(onNext: { [weak self] error in
                self?.isLoadingRelay.onNext(false)
                self?.loginErrorRelay.onNext(error)
            })
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            loginError: loginErrorRelay.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToMain: shouldNavigateToMainRelay.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToRegister: shouldNavigateToRegisterRelay.asDriver(onErrorDriveWith: .empty()),
            shouldHideSplash: shouldHideSplashRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}

private extension LoginViewModel {
    /// - 이메일 로그인 서버 검증
    func loginWithEmail(email: String, password: String) {
        guard !email.isEmpty && !password.isEmpty
        else { loginErrorRelay.onNext(.invalidCredentials); return }
        
        isLoadingRelay.onNext(true)
        
        // TODO: 이메일 검증 API 추가
        /// - Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoadingRelay.onNext(false)
            self?.loginErrorRelay.onNext(.notImplemented)
        }
    }
    /// - 애플 로그인 서버 검증
    func processAppleLogin(_ appleResult: AppleLoginResult) {
        isLoadingRelay.onNext(true)
        
        let loginResult = LoginResult.apple(appleResult)
        
        // TODO: 이메일 검증 API 추가
        /// - Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoadingRelay.onNext(false)
            self?.handleLoginSuccess(loginResult)
        }
    }
    
    func handleLoginSuccess(_ result: LoginResult) {
        switch result {
        case let .apple(result):
            KeyChainManager.shared.save(.lastLoginStatus, value: "apple")
            
            if let email = result.email {
                KeyChainManager.shared.save(.email, value: email)
            }
            
            if let idToken = result.idToken,
               let idTokenString = String(data: idToken, encoding: .utf8) {
                KeyChainManager.shared.save(.idToken, value: idTokenString)
            }
            
        case let .email(token, user):
            KeyChainManager.shared.save(.lastLoginStatus, value: "email")
        }
        
        shouldNavigateToMainRelay.onNext(())
    }
    
    func isUserLoggedIn() -> Bool {
        guard let lastLoginStatus = KeyChainManager.shared.read(.lastLoginStatus) else { return false }
        return !lastLoginStatus.isEmpty
    }
}

// MARK: - Models
enum LoginResult {
    case email(token: String, user: User)
    case apple(AppleLoginResult)
}

struct AppleLoginResult {
    let email: String?
    let idToken: Data?
    let authorizationCode: Data?
}

enum LoginError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case userCanceled
    case authenticationFailed
    case invalidResponse
    case notHandled
    case unknown
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .userCanceled:
            return "사용자가 로그인을 취소했습니다."
        case .authenticationFailed:
            return "인증에 실패했습니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .notHandled:
            return "처리되지 않은 오류입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .notImplemented:
            return "아직 구현되지 않은 기능입니다."
        }
    }
}

// MARK: - User Model (if not exists)
struct User {
    let id: String
    let email: String
    let name: String?
}
