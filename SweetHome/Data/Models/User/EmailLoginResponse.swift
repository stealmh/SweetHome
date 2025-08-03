//
//  EmailLoginResponse.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

struct LoginResponse: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}
