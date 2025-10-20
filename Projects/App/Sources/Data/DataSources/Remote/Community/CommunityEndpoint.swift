//
//  CommunityEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import Alamofire
import CoreNetwork

enum CommunityEndpoint: TargetType {
    /// - 게시물 조회
    case posts(parameter: CommunityPostsRequest)
    /// - 게시물 상세 조회
    case postDetail(id: String)
}

extension CommunityEndpoint {
    var baseURL: String {
        return APIConstants.baseURL
    }
    
    var path: String {
        switch self {
        case .posts:
            return "/v1/posts/geolocation"
        case let .postDetail(id):
            return "/v1/posts/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .posts, .postDetail:
            return .get
        }
    }
    
    var task: HTTPTask {
        switch self {
        case let .posts(parameter):
            return .requestParameters(parameters: parameter.toDictionary(), encoding: URLEncoding.default)
        case .postDetail:
            return .requestPlain
        }
    }
    
    var headers: HTTPHeaders? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
        return HTTPHeaders([
            "SeSACKey": key,
            "Content-Type": "application/json"
        ])
    }
}
