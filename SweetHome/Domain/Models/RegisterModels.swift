//
//  RegisterModels.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

// MARK: - Data Models
struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}

struct RegisterResponse: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}
