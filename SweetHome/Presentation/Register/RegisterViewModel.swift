//
//  RegisterViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import Foundation
import RxSwift
import RxCocoa

class RegisterViewModel: BaseViewModel {
    
    struct Input {
        let email: Observable<String>
        let password: Observable<String>
        let nickname: Observable<String>
        let phone: Observable<String>
        let description: Observable<String>
        let registerTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let shouldNavigateToMain: Driver<Void>
        let registerButtonEnable: Driver<Bool>
        let error: Driver<RegisterError>
        let emailValidationState: Driver<EmailValidationState>
    }
    
    private let userClient: UserClient
    private let emailValidator: EmailValidator
    
    init(network: NetworkServiceProtocol = NetworkService.shared) {
        self.userClient = UserClient(network: network)
        self.emailValidator = EmailValidator(userClient: userClient)
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let registerErrorRelay = PublishSubject<RegisterError>()
        let navigateToMainSubject = PublishSubject<Void>()
        
        // 회원가입 버튼 활성화 로직
        let registerButtonEnable = Observable.combineLatest(
            input.email,
            input.password,
            input.nickname
        )
            .map { (email, password, nickname) -> Bool in
                return email.isValidEmail &&
                password.count >= 8 &&
                !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .startWith(false)
            .distinctUntilChanged()
        
        let emailValidationResult = emailValidator
            .validateEmailStream(input.email)
            .share(replay: 1)
        
        input.registerTapped
            .withLatestFrom(Observable.combineLatest(
                input.email,
                input.password,
                input.nickname,
                input.phone,
                input.description
            ))
            .flatMap { [weak self] (email, password, nickname, phone, introduction) -> Observable<Void> in
                guard let self else { return Observable.empty() }
                
                print("🔥 withLatestFrom 실행됨: email=\(email), password=\(password), nickname=\(nickname)")
                
                let requestModel = RegisterRequest(
                    email: email,
                    password: password,
                    nick: nickname,
                    phoneNum: phone,
                    introduction: introduction,
                    deviceToken: nil
                )
                print("회원가입 요청 받음: \(requestModel)")
                
                // 유효성 검사
                if let validationError = self.validateRegistrationData(email: email, password: password, nickname: nickname) {
                    registerErrorRelay.onNext(validationError)
                    return Observable.empty()
                }
                
                print("모든 유효성 검사 통과, 회원가입 진행")
                isLoadingRelay.onNext(true)
                
                return self.performRegistration(
                    requestModel: requestModel,
                    isLoadingRelay: isLoadingRelay,
                    registerErrorRelay: registerErrorRelay,
                    navigateToMainSubject: navigateToMainSubject
                )
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        // 메인 화면으로 이동 (회원가입 성공 시)
        let shouldNavigateToMain = navigateToMainSubject.asObservable()
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            shouldNavigateToMain: shouldNavigateToMain.asDriver(onErrorDriveWith: .empty()),
            registerButtonEnable: registerButtonEnable.asDriver(onErrorDriveWith: .empty()),
            error: registerErrorRelay.asDriver(onErrorDriveWith: .empty()),
            emailValidationState: emailValidationResult.asDriver(onErrorDriveWith: .empty())
        )
    }
}

// MARK: - Private Methods
private extension RegisterViewModel {
    
    /// 회원가입 데이터 유효성 검사
    func validateRegistrationData(email: String, password: String, nickname: String) -> RegisterError? {
        guard email.isValidEmail else { return .invalidEmail }
        guard password.isValidPassword else { return .weakPassword }
        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .emptyNickname }
        
        return nil
    }
    
    /// 회원가입 네트워크 요청 수행
    func performRegistration(
        requestModel: RegisterRequest,
        isLoadingRelay: BehaviorSubject<Bool>,
        registerErrorRelay: PublishSubject<RegisterError>,
        navigateToMainSubject: PublishSubject<Void>
    ) -> Observable<Void> {
        
        return userClient.request(.emailRegister(requestModel))
            .do(
                onNext: { [weak self] (response: RegisterResponse) in
                    self?.handleRegistrationSuccess(
                        response: response,
                        isLoadingRelay: isLoadingRelay,
                        navigateToMainSubject: navigateToMainSubject
                    )
                },
                onError: { error in
                    self.handleRegistrationError(
                        error: error,
                        isLoadingRelay: isLoadingRelay,
                        registerErrorRelay: registerErrorRelay
                    )
                }
            )
            .map { _ in () }
            .catchAndReturn(())
    }
    
    /// 회원가입 성공 처리
    func handleRegistrationSuccess(
        response: RegisterResponse,
        isLoadingRelay: BehaviorSubject<Bool>,
        navigateToMainSubject: PublishSubject<Void>
    ) {
        print("✅ 회원가입 성공")
        isLoadingRelay.onNext(false)
        
        // 토큰 저장
        KeyChainManager.shared.save(.accessToken, value: response.accessToken)
        KeyChainManager.shared.save(.refreshToken, value: response.refreshToken)
        
        // 메인 화면으로 이동
        navigateToMainSubject.onNext(())
    }
    
    /// 회원가입 실패 처리
    func handleRegistrationError(
        error: Error,
        isLoadingRelay: BehaviorSubject<Bool>,
        registerErrorRelay: PublishSubject<RegisterError>
    ) {
        print("❌ 회원가입 실패: \(error)")
        isLoadingRelay.onNext(false)
        registerErrorRelay.onNext(.networkError(error))
    }
}
