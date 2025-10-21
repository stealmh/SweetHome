//
//  RegisterResponse.swift
//  Auth
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

public struct RegisterResponse: Decodable {
    public let user_id: String
    public let email: String
    public let nick: String
    public let accessToken: String
    public let refreshToken: String
    
    public init(user_id: String, email: String, nick: String, accessToken: String, refreshToken: String) {
        self.user_id = user_id
        self.email = email
        self.nick = nick
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
