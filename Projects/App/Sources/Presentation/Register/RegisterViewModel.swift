//
//  RegisterViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import Foundation
import RxSwift
import RxCocoa

import AuthInterface

class RegisterViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
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
        let error: Driver<SHError>
        let emailValidationError: Driver<SHError?>
    }
    
    private let useCase: RegisterUseCase
    private let emailValidator: EmailValidator

    init(
        useCase: RegisterUseCase = RegisterUseCaseImpl(
            repository: RegisterRepositoryImpl()
        ),
        apiClient: ApiClient = ApiClient.shared
    ) {
        self.useCase = useCase
        self.emailValidator = EmailValidator(apiClient: apiClient)
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let registerErrorRelay = PublishSubject<SHError>()
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
                
                let requestModel = RegisterInfo(
                    email: email,
                    password: password,
                    nickname: nickname,
                    phoneNumber: phone,
                    introduction: introduction,
                    deviceToken: nil
                )
                print("회원가입 요청 받음: \(requestModel)")

                // 유효성 검사
                if let validationError = self.useCase.validateRegistrationData(email: email, password: password, nickname: nickname) {
                    registerErrorRelay.onNext(validationError)
                    return Observable.empty()
                }

                print("모든 유효성 검사 통과, 회원가입 진행")
                isLoadingRelay.onNext(true)

                return self.useCase.register(registerInfo: requestModel)
                    .do(
                        onNext: { response in
                            print("✅ 회원가입 성공")
                            isLoadingRelay.onNext(false)
                            navigateToMainSubject.onNext(())
                        },
                        onError: { error in
                            print("❌ 회원가입 실패: \(error)")
                            isLoadingRelay.onNext(false)
                            let shError = SHError.from(error)
                            registerErrorRelay.onNext(shError)
                        }
                    )
                    .map { _ in () }
                    .catchAndReturn(())
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
            emailValidationError: emailValidationResult.asDriver(onErrorDriveWith: .just(nil))
        )
    }
}

