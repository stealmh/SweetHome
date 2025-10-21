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
import CoreStorage

import AuthInterface
import Auth

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
    private let loginUseCase: LoginUseCase

    init(
        loginUseCase: LoginUseCase = LoginUseCaseImpl(
            authRepository: AuthRepositoryImpl(
                apiClient: ApiClient.shared,
                keychainManager: KeyChainManager.shared
            ),
            loginSession: LoginSession()
        )
    ) {
        self.loginUseCase = loginUseCase
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

                isLoadingRelay.onNext(true)

                return self.loginUseCase.loginWithEmail(email: email, password: password)
                    .do(
                        onNext: { _ in
                            isLoadingRelay.onNext(false)
                            navigateToMainSubject.onNext(())
                        },
                        onError: { error in
                            isLoadingRelay.onNext(false)
                            let shError = SHError.from(error)
                            loginErrorRelay.onNext(shError)
                        }
                    )
                    .catchAndReturn(())
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        input.kakaoLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<Void> in
                isLoadingRelay.onNext(true)

                return owner.loginUseCase.loginWithKakao()
                    .do(
                        onNext: { _ in
                            isLoadingRelay.onNext(false)
                            navigateToMainSubject.onNext(())
                        },
                        onError: { error in
                            isLoadingRelay.onNext(false)
                            let shError = SHError.from(error)
                            loginErrorRelay.onNext(shError)
                        }
                    )
                    .catchAndReturn(())
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        let registerTapped = input.registerTapped
        
        input.appleLoginTapped
            .withUnretained(self)
            .flatMapLatest { owner, presentationContext -> Observable<Void> in
                isLoadingRelay.onNext(true)

                return owner.loginUseCase.loginWithApple(presentationContext: presentationContext)
                    .do(
                        onNext: { _ in
                            isLoadingRelay.onNext(false)
                            navigateToMainSubject.onNext(())
                        },
                        onError: { error in
                            isLoadingRelay.onNext(false)
                            let shError = SHError.from(error)
                            loginErrorRelay.onNext(shError)
                        }
                    )
                    .catchAndReturn(())
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        let appleLoginError = loginUseCase.getAppleLoginError()
            .do(onNext: { error in
                isLoadingRelay.onNext(false)
                loginErrorRelay.onNext(error)
            })
            .map { _ in () }
        
        let shouldNavigateToMain = navigateToMainSubject.asObservable()
        
        let loginButtonEnable = Observable.combineLatest(input.email, input.password)
            .map { [weak self] (email, password) -> Bool in
                guard let self = self else { return false }
                return self.loginUseCase.validateLoginData(email: email, password: password) == nil
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


