//
//  ReIssueResponse.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

public struct ReIssueResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
