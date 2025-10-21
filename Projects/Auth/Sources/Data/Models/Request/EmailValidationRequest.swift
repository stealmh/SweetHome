//
//  EmailValidationRequest.swift
//  Auth
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

public struct EmailValidationRequest: Encodable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}
