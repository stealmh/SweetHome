//
//  EmailValidator.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import RxSwift

class EmailValidator {
    private let userClient: UserClient
    
    init(userClient: UserClient) {
        self.userClient = userClient
    }
    
    func validateEmail(_ email: String) -> Observable<EmailValidationState> {
        // 1. 빈 값 체크
        if email.isEmpty {
            return Observable.just(.idle)
        }
        
        // 2. 이메일 형식 체크
        if !email.isValidEmail {
            return Observable.just(.invalid("잘못된 형식입니다."))
        }
        
        // 3. API 호출
        return checkEmailAvailability(email)
    }
    
    func validateEmailStream(_ emailStream: Observable<String>) -> Observable<EmailValidationState> {
        return emailStream
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] email -> Observable<EmailValidationState> in
                guard let self = self else { return Observable.just(.error) }
                return self.validateEmail(email)
            }
            .startWith(.idle)
    }
    
    private func checkEmailAvailability(_ email: String) -> Observable<EmailValidationState> {
        return Observable.just(.checking)
            .concat(
                Observable.just(email)
                    .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
                    .flatMapLatest { [weak self] validEmail -> Observable<EmailValidationState> in
                        guard let self = self else { return Observable.just(.error) }
                        
                        let requestModel = EmailValidationRequest(email: validEmail)
                        return self.userClient.request(.emailValidation(requestModel))
                            .map { (response: BaseResponse) -> EmailValidationState in
                                return .available
                            }
                            .catch { error -> Observable<EmailValidationState> in
                                if let networkError = error as? SHError.NetworkError,
                                   let statusCode = networkError.statusCode {
                                    switch statusCode {
                                    case 400:
                                        return Observable.just(.invalid("필수값을 채워주세요."))
                                    case 409:
                                        return Observable.just(.unavailable)
                                    default:
                                        return Observable.just(.error)
                                    }
                                }
                                return Observable.just(.error)
                            }
                    }
            )
    }
}