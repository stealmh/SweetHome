//
//  EmailValidator.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import RxSwift
import Alamofire

class EmailValidator {
    private let userClient: UserClient
    
    init(userClient: UserClient) {
        self.userClient = userClient
    }
    
    func validateEmail(_ email: String) -> Observable<SHError?> {
        /// [1]. 이메일 값이 비어있는지 확인 (클라이언트 검증)
        if email.isEmpty { return Observable.just(nil) }
        
        /// [2]. 이메일 형식 확인 (클라이언트 검증)
        if !email.isValidEmail { return Observable.just(.clientError(.textfield(.invalidEmailFormat))) }

        // 서버 검증이 필요한 경우만 API 호출
        return checkEmailAvailability(email)
    }
    
    func validateEmailStream(_ emailStream: Observable<String>) -> Observable<SHError?> {
        return emailStream
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] email -> Observable<SHError?> in
                guard let self else { return Observable.just(.commonError(.weakSelfFailure)) }
                return self.validateEmail(email)
            }
            .startWith(nil)
    }
    
    private func checkEmailAvailability(_ email: String) -> Observable<SHError?> {
        let requestModel = EmailValidationRequest(email: email)
        return self.userClient.request(.emailValidation(requestModel))
            .map { (response: BaseResponse) -> SHError? in
                return nil
            }
            .catch { handleEmailValidationError($0) }
    }
}
