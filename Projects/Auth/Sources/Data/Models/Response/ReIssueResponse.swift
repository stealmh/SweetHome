//
//  ReIssueResponse.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

struct ReIssueResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
