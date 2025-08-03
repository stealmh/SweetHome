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

class LoginViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let onAppear: Observable<Void>
        let email: Observable<String>
        let password: Observable<String>
        let emailLoginTapped: Observable<Void>
        let registerTapped: Observable<Void>
        let appleLoginTapped: Observable<ASAuthorizationControllerPresentationContextProviding>
        let kakaoLoginTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let shouldNavigateToMain: Driver<Void>
        let shouldNavigateToRegister: Driver<Void>
        let loginButtonEnable: Driver<Bool>
        let error: Driver<SHError>
    }
    
    
    // MARK: - Dependencies
    private let userClient: UserClient
    private let loginSession: LoginSessionProtocol
    
    init(network: NetworkServiceProtocol = NetworkService.shared, loginSession: LoginSessionProtocol = LoginSession()) {
        self.userClient = UserClient(network: network)
        self.loginSession = loginSession
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let loginErrorRelay = PublishSubject<SHError>()
        let navigateToMainSubject = PublishSubject<Void>()
        
        let onAppear = input.onAppear.share()
        
        input.emailLoginTapped
            .withLatestFrom(Observable.combineLatest(input.email, input.password))
            .flatMap { [weak self] (email, password) -> Observable<Void> in
                guard let self else { return Observable.empty() }
                
                // 유효성 검사
                if let validationError = self.validateLoginData(email: email, password: password) {
                    loginErrorRelay.onNext(validationError)
                    return Observable.empty()
                }
                
                isLoadingRelay.onNext(true)
                
                let requestModel = EmailLoginRequest(email: email, password: password, deviceToken: nil)
                
                return self.performEmailLogin(
                    requestModel: requestModel,
                    isLoadingRelay: isLoadingRelay,
                    loginErrorRelay: loginErrorRelay,
                    navigateToMainSubject: navigateToMainSubject
                )
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        input.kakaoLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<SocialLoginResponse> in
                isLoadingRelay.onNext(true)
                return owner.loginSession.performKakaoLogin()
            }
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self else { return Observable.empty() }

                let requestModel = KakaoLoginRequest(oauthToken: socialLoginResponse.idToken, deviceToken: nil)
                
                return self.performKakaoLogin(
                    requestModel: requestModel,
                    isLoadingRelay: isLoadingRelay,
                    loginErrorRelay: loginErrorRelay,
                    navigateToMainSubject: navigateToMainSubject
                )
            }
            .catch { error -> Observable<Void> in
                isLoadingRelay.onNext(false)
                let shError = SHError.from(error)
                loginErrorRelay.onNext(shError)
                return Observable.empty()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        let registerTapped = input.registerTapped
        
        input.appleLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, presentationContext -> Observable<SocialLoginResponse> in
                isLoadingRelay.onNext(true)
                return owner.loginSession.performAppleLogin(presentationContext: presentationContext)
            }
            .flatMap { [weak self] socialLoginResponse -> Observable<Void> in
                guard let self = self else { return Observable.empty() }
                
                print("🔥 애플 로그인 성공, 서버 인증 시작")
                
                let requestModel = AppleLoginRequest(
                    idToken: socialLoginResponse.idToken,
                    deviceToken: nil,
                    nick: socialLoginResponse.name ?? ""
                )
                
                return self.performAppleLogin(
                    requestModel: requestModel,
                    isLoadingRelay: isLoadingRelay,
                    loginErrorRelay: loginErrorRelay,
                    navigateToMainSubject: navigateToMainSubject
                )
            }
            .catch { error -> Observable<Void> in
                isLoadingRelay.onNext(false)
                let shError = SHError.from(error)
                loginErrorRelay.onNext(shError)
                return Observable.empty()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        let appleLoginError = loginSession.getAppleLoginError()
            .do(onNext: { error in
                isLoadingRelay.onNext(false)
                loginErrorRelay.onNext(SHError.from(error))
            })
            .map { _ in () }
        
        let shouldNavigateToMain = navigateToMainSubject.asObservable()
        
        let loginButtonEnable = Observable.combineLatest(input.email, input.password)
            .map { (email, password) -> Bool in
                return email.isValidEmail && password.isValidPassword
            }
            .startWith(false)
            .distinctUntilChanged()
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToMain: shouldNavigateToMain.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToRegister: registerTapped.asDriver(onErrorDriveWith: .empty()),
            loginButtonEnable: loginButtonEnable.asDriver(onErrorDriveWith: .empty()),
            error: loginErrorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}

private extension LoginViewModel {
    /// 이메일 로그인 데이터 유효성 검사
    func validateLoginData(email: String, password: String) -> SHError? {
        /// 🚨 Case [1]. 잘못된 이메일 형식
        guard email.isValidEmail else { return .clientError(.textfield(.invalidEmailFormat)) }
        /// 🚨 Case [2]. 잘못된 비밀번호 형식
        guard password.isValidPassword else { return .clientError(.textfield(.invalidEmailFormat)) }
        
        return nil
    }
    
    /// 이메일 로그인 네트워크 요청 수행
    func performEmailLogin(
        requestModel: EmailLoginRequest,
        isLoadingRelay: BehaviorSubject<Bool>,
        loginErrorRelay: PublishSubject<SHError>,
        navigateToMainSubject: PublishSubject<Void>
    ) -> Observable<Void> {
        
        return userClient.request(.emailLogin(requestModel))
            .do(
                onNext: { [weak self] (response: LoginResponse) in
                    self?.handleLoginSuccess(
                        response: response,
                        isLoadingRelay: isLoadingRelay,
                        navigateToMainSubject: navigateToMainSubject
                    )
                },
                onError: { error in
                    self.handleLoginError(
                        error: error,
                        isLoadingRelay: isLoadingRelay,
                        loginErrorRelay: loginErrorRelay
                    )
                }
            )
            .map { _ in () }
            .catchAndReturn(())
    }
    
    /// 이메일 로그인 성공 처리
    func handleLoginSuccess(
        response: LoginResponse,
        isLoadingRelay: BehaviorSubject<Bool>,
        navigateToMainSubject: PublishSubject<Void>
    ) {
        print("✅ 이메일 로그인 성공")
        isLoadingRelay.onNext(false)
        
        // 토큰 저장
        KeyChainManager.shared.save(.accessToken, value: response.accessToken)
        KeyChainManager.shared.save(.refreshToken, value: response.refreshToken)
        KeyChainManager.shared.save(.lastLoginStatus, value: "email")
        
        // 메인 화면으로 이동
        navigateToMainSubject.onNext(())
    }
    
    /// 이메일 로그인 실패 처리
    func handleLoginError(
        error: Error,
        isLoadingRelay: BehaviorSubject<Bool>,
        loginErrorRelay: PublishSubject<SHError>
    ) {
        print("❌ 이메일 로그인 실패: \(error)")
        isLoadingRelay.onNext(false)
        
        // SHError.from을 사용하여 통합 에러 처리
        let shError = SHError.from(error)
        
        // 특별한 경우 처리
        loginErrorRelay.onNext(shError)
    }
    
    /// 카카오 로그인 네트워크 요청 수행
    func performKakaoLogin(
        requestModel: KakaoLoginRequest,
        isLoadingRelay: BehaviorSubject<Bool>,
        loginErrorRelay: PublishSubject<SHError>,
        navigateToMainSubject: PublishSubject<Void>
    ) -> Observable<Void> {
        
        return userClient.request(.kakaoLogin(requestModel))
            .do(
                onNext: { [weak self] (response: LoginResponse) in
                    self?.handleSocialLoginSuccess(
                        response: response,
                        loginType: "kakao",
                        isLoadingRelay: isLoadingRelay,
                        navigateToMainSubject: navigateToMainSubject
                    )
                },
                onError: { error in
                    self.handleSocialLoginError(
                        error: error,
                        loginType: "kakao",
                        isLoadingRelay: isLoadingRelay,
                        loginErrorRelay: loginErrorRelay
                    )
                }
            )
            .map { _ in () }
            .catchAndReturn(())
    }
    
    /// 애플 로그인 네트워크 요청 수행
    func performAppleLogin(
        requestModel: AppleLoginRequest,
        isLoadingRelay: BehaviorSubject<Bool>,
        loginErrorRelay: PublishSubject<SHError>,
        navigateToMainSubject: PublishSubject<Void>
    ) -> Observable<Void> {
        return userClient.request(.appleLogin(requestModel))
            .do(
                onNext: { [weak self] (response: LoginResponse) in
                    self?.handleSocialLoginSuccess(
                        response: response,
                        loginType: "apple",
                        isLoadingRelay: isLoadingRelay,
                        navigateToMainSubject: navigateToMainSubject
                    )
                },
                onError: { error in
                    self.handleSocialLoginError(
                        error: error,
                        loginType: "apple",
                        isLoadingRelay: isLoadingRelay,
                        loginErrorRelay: loginErrorRelay
                    )
                }
            )
            .map { _ in () }
            .catchAndReturn(())
    }
    
    /// 소셜 로그인 성공 처리
    func handleSocialLoginSuccess(
        response: LoginResponse,
        loginType: String,
        isLoadingRelay: BehaviorSubject<Bool>,
        navigateToMainSubject: PublishSubject<Void>
    ) {
        print("✅ \(loginType) 로그인 성공")
        isLoadingRelay.onNext(false)
        
        // 토큰 저장
        KeyChainManager.shared.save(.accessToken, value: response.accessToken)
        KeyChainManager.shared.save(.refreshToken, value: response.refreshToken)
        KeyChainManager.shared.save(.lastLoginStatus, value: loginType)
        
        // 메인 화면으로 이동
        navigateToMainSubject.onNext(())
    }
    
    /// 소셜 로그인 실패 처리
    func handleSocialLoginError(
        error: Error,
        loginType: String,
        isLoadingRelay: BehaviorSubject<Bool>,
        loginErrorRelay: PublishSubject<SHError>
    ) {
        print("❌ \(loginType) 로그인 실패: \(error)")
        isLoadingRelay.onNext(false)
        let shError = SHError.from(error)
        loginErrorRelay.onNext(shError)
    }
}

