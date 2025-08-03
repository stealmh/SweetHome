//
//  EmailLoginRequest.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

struct EmailLoginRequest: Encodable {
    let email: String
    let password: String
    let deviceToken: String?
}
