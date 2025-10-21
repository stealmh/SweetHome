//
//  AuthEndpoint.swift
//  Auth
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import Alamofire
import CoreNetwork
import CoreStorage

public enum AuthEndpoint: TargetType {
    /// - 토큰 리프래시
    case refresh(refreshToken: String, keychainManager: KeyChainManagerProtocol)
}

extension AuthEndpoint {
    public var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
    }

    public var path: String {
        switch self {
        case .refresh:
            return "/v1/auth/refresh"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .refresh:
            return .get
        }
    }

    public var headers: HTTPHeaders? {
        switch self {
        case let .refresh(refreshToken, keychainManager):
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }

            let accessToken = keychainManager.read(.accessToken) ?? ""
            return HTTPHeaders([
                "Authorization": accessToken,
                "RefreshToken": refreshToken,
                "SeSACKey": key
            ])
        }
    }

    public var task: HTTPTask {
        switch self {
        case .refresh:
            return .requestPlain
        }
    }
}
