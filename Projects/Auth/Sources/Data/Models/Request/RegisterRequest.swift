//
//  RegisterRequest.swift
//  Auth
//
//  Created by 김민호 on 7/30/25.
//

import Foundation

public struct RegisterRequest: Encodable {
    public let email: String
    public let password: String
    public let nick: String
    public let phoneNum: String?
    public let introduction: String?
    public let deviceToken: String?
    
    public init(email: String, password: String, nick: String, phoneNum: String?, introduction: String?, deviceToken: String?) {
        self.email = email
        self.password = password
        self.nick = nick
        self.phoneNum = phoneNum
        self.introduction = introduction
        self.deviceToken = deviceToken
    }
}
