//
//  LoginModels.swift
//  SweetHome
//
//  Created by 김민호 on 7/29/25.
//

import Foundation

// MARK: - Login Result
enum LoginResult {
    case email(token: String)
    case apple(SocialLoginResponse)
    case kakao(SocialLoginResponse)
}