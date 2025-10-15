//
//  RegisterRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 회원가입 관련 데이터 접근을 추상화하는 Repository
protocol RegisterRepository {
    /// - 이메일 회원가입
    /// - Parameter request: 회원가입 요청 데이터
    func register(request: RegisterRequest) -> Observable<RegisterResponse>
}
