//
//  AppleLoginRequest.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

struct AppleLoginRequest: Encodable {
    let idToken: String
    let deviceToken: String?
    let nick: String
}