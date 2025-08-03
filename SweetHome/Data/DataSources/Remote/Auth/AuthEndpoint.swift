//
//  AuthEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import Alamofire

enum AuthEndpoint: TargetType {
    /// - 토큰 리프래시
    case refresh(refreshToken: String)
}

extension AuthEndpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else { return "" }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .refresh:
            return "auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .refresh:
            return .get
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case let .refresh(refreshToken):
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
            return [
                "RefreshToken": refreshToken,
                "SeSACKey": key
            ]
        }
    }
}
