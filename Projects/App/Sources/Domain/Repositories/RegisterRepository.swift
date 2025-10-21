//
//  RegisterRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift
import AuthInterface

/// - 회원가입 관련 데이터 접근을 추상화하는 Repository
public protocol RegisterRepository {
    /// - 이메일 회원가입
    /// - Parameter registerInfo: 회원가입 정보
    /// - Returns: 회원가입 결과 (사용자 정보 + 토큰)
    func register(registerInfo: RegisterInfo) -> Observable<RegisterResult>
}
