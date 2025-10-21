//
//  EmailLoginRequest.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

public struct EmailLoginRequest: Encodable {
    public let email: String
    public let password: String
    public let deviceToken: String?
}
