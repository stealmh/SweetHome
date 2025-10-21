//
//  AppleLoginRequest.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

public struct AppleLoginRequest: Encodable {
    public let idToken: String
    public let deviceToken: String?
    public let nick: String
}
