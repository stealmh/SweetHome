//
//  EstateEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation
import Alamofire

enum EstateEndpoint: TargetType {
    case todayEstates
    case hotEstates
    case topics
    case geoLocation(parameter: EstateGeoLocationRequest)
    case detail(id: String)
    /// 매물 좋아요 / 좋아요 취소
    case like(id: String, body: DetailEstateLikeStatus)
    /// 유사한 매물 목록
    case similarEstates
    case search(query: String)
}

extension EstateEndpoint {
    var baseURL: String {
        switch self {
        case .search:
            return "https://dapi.kakao.com"
        default: return APIConstants.baseURL
        }
    }
    
    var path: String {
        switch self {
        case .todayEstates:
            return "/v1/estates/today-estates"
        case .hotEstates:
            return "/v1/estates/hot-estates"
        case .topics:
            return "/v1/estates/today-topic"
        case .geoLocation:
            return "/v1/estates/geolocation"
        case let .detail(id):
            return "/v1/estates/\(id)"
        case let .like(id, _):
            return "/v1/estates/\(id)/like"
        case .similarEstates:
            return "/v1/estates/similar-estates"
        case .search:
            return "/v2/local/search/address.json"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .todayEstates, .hotEstates, .topics, .geoLocation, .detail, .similarEstates, .search:
            return .get
        case .like:
            return .post
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .todayEstates, .hotEstates, .topics, .detail, .similarEstates:
            return .requestPlain
        case let .geoLocation(parameter):
            return .requestParameters(parameters: parameter.toDictionary(), encoding: URLEncoding.default)
        case let .search(query):
            return .requestParameters(parameters: ["query": query], encoding: URLEncoding.default)
        case let .like(_, model):
            return .requestJSONEncodable(model)
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .search:
            guard let key = Bundle.main.object(forInfoDictionaryKey: "REST_API_KEY") as? String else { return nil }
            return HTTPHeaders([
                "Authorization":"KakaoAK \(key)",
                "Content-Type": "application/json;charset=UTF-8"
            ])
        default:
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
            return HTTPHeaders([
                "SeSACKey": key,
                "Content-Type": "application/json"
            ])
        }
    }
}
