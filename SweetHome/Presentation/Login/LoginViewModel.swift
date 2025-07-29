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
        let kakaoLoginTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let shouldNavigateToMain: Driver<Void>
        let shouldNavigateToRegister: Driver<Void>
        let shouldHideSplash: Driver<Void>
        let kakaoLoginResult: Driver<Void>
        let error: Driver<LoginError>
    }
    
    
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
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let loginErrorRelay = PublishSubject<LoginError>()
        
        let onAppear = input.onAppear
            .delay(.seconds(2), scheduler: MainScheduler.instance)
            .share()
        
        let emailLoginTapped = input.emailLoginTapped
            .do(onNext: { credentials in
                guard !credentials.email.isEmpty && !credentials.password.isEmpty else {
                    loginErrorRelay.onNext(.invalidCredentials)
                    return
                }
                
                isLoadingRelay.onNext(true)
                
                // TODO: 이메일 검증 API 추가
                // Mock implementation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLoadingRelay.onNext(false)
                    loginErrorRelay.onNext(.notImplemented)
                }
            })
            .map { _ in () }
        
        let kakaoLoginTapped = input.kakaoLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<SocialLoginResponse> in
                isLoadingRelay.onNext(true)
                return owner.loginSession.performKakaoLogin()
                    .do(onNext: { oauthToken in
                        // TODO: 카카오 토큰으로 서버 인증 API 호출
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isLoadingRelay.onNext(false)
                            // 임시로 키체인에 카카오 로그인 상태 저장
                            KeyChainManager.shared.save(.lastLoginStatus, value: "kakao")
                        }
                    })
                    .catch { error -> Observable<SocialLoginResponse> in
                        isLoadingRelay.onNext(false)
                        loginErrorRelay.onNext(.networkError(error))
                        return Observable.empty()
                    }
            }
            .share()
        
        let registerTapped = input.registerTapped
        
        let appleLoginTapped = input.appleLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, presentationContext -> Observable<SocialLoginResponse> in
                isLoadingRelay.onNext(true)
                return owner.loginSession.performAppleLogin(presentationContext: presentationContext)
                    .do(onNext: { loginResult in
                        isLoadingRelay.onNext(true)
                        
                        let result = LoginResult.apple(loginResult)
                        
                        // TODO: 이메일 검증 API 추가
                        // Mock implementation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isLoadingRelay.onNext(false)
                            // Handle login success
                            KeyChainManager.shared.save(.lastLoginStatus, value: "apple")
                            KeyChainManager.shared.save(.idToken, value: loginResult.idToken)
                        }
                    })
            }
            .share()
        
        let appleLoginError = loginSession.getAppleLoginError()
            .do(onNext: { error in
                isLoadingRelay.onNext(false)
                loginErrorRelay.onNext(error)
            })
            .map { _ in () }
        
        // Navigation and result streams
        let shouldNavigateToMain = Observable.merge(
            onAppear
                .withUnretained(self)
                .compactMap { owner, _ in
                    owner.isUserLoggedIn() ? () : nil
                },
            kakaoLoginTapped.map { _ in () },
            appleLoginTapped.map { _ in () }
        )
        
        let shouldHideSplash = onAppear
            .withUnretained(self)
            .compactMap { owner, _ in
                !owner.isUserLoggedIn() ? () : nil
            }
        
        let kakaoLoginResult = kakaoLoginTapped
            .map { _ in () }
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToMain: shouldNavigateToMain.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToRegister: registerTapped.asDriver(onErrorDriveWith: .empty()),
            shouldHideSplash: shouldHideSplash.asDriver(onErrorDriveWith: .empty()),
            kakaoLoginResult: kakaoLoginResult.asDriver(onErrorDriveWith: .empty()),
            error: loginErrorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}

private extension LoginViewModel {
    func isUserLoggedIn() -> Bool {
        guard let lastLoginStatus = KeyChainManager.shared.read(.lastLoginStatus) else { return false }
        return !lastLoginStatus.isEmpty
    }
}

