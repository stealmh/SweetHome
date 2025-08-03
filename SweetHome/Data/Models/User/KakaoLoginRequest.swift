//
//  KakaoLoginRequest.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

struct KakaoLoginRequest: Encodable {
    let oauthToken: String
    let deviceToken: String?
}