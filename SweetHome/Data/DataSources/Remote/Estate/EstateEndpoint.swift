//
//  EstateEndpoint.swift
//  SweetHome
//
//  Created by Claude on 8/3/25.
//

import Foundation
import Alamofire

enum EstateEndpoint: TargetType {
    case getEstateList(page: Int, limit: Int)
    case getEstateDetail(id: Int)
    case searchEstate(query: String, page: Int)
    case getEstatesByCategory(category: String, page: Int)
    case createEstate
    case updateEstate(id: Int)
    case deleteEstate(id: Int)
    case favoriteEstate(id: Int)
    case unfavoriteEstate(id: Int)
    case getFavoriteEstates
}

extension EstateEndpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else { return "" }
        return baseURL
    }
    
    var path: String {
        switch self {
        case .getEstateList:
            return "estate"
        case .getEstateDetail(let id):
            return "estate/\(id)"
        case .searchEstate:
            return "estate/search"
        case .getEstatesByCategory:
            return "estate/category"
        case .createEstate:
            return "estate"
        case .updateEstate(let id):
            return "estate/\(id)"
        case .deleteEstate(let id):
            return "estate/\(id)"
        case .favoriteEstate(let id):
            return "estate/\(id)/favorite"
        case .unfavoriteEstate(let id):
            return "estate/\(id)/favorite"
        case .getFavoriteEstates:
            return "estate/favorites"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getEstateList, .getEstateDetail, .searchEstate, .getEstatesByCategory, .getFavoriteEstates:
            return .get
        case .createEstate, .favoriteEstate:
            return .post
        case .updateEstate:
            return .put
        case .deleteEstate, .unfavoriteEstate:
            return .delete
        }
    }
    
    var headers: [String: String]? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SESAC_KEY") as? String else { return nil }
        return [
            "SeSACKey": key,
            "Content-Type": "application/json"
        ]
    }
}