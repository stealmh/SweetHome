//
//  KakaoLoginRequest.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

public struct KakaoLoginRequest: Encodable {
    public let oauthToken: String
    public let deviceToken: String?
    
    public init(oauthToken: String, deviceToken: String?) {
        self.oauthToken = oauthToken
        self.deviceToken = deviceToken
    }
}
