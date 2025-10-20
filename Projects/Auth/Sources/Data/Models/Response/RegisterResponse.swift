//
//  RegisterResponse.swift
//  Auth
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

struct RegisterResponse: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}
