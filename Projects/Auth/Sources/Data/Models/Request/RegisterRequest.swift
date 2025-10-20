//
//  RegisterRequest.swift
//  Auth
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}
