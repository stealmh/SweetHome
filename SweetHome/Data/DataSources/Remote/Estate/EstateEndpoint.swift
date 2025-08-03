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
}

extension EstateEndpoint {
    var baseURL: String { return APIConstants.baseURL }
    
    var path: String {
        switch self {
        case .todayEstates:
            return "/estates/today-estates"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .todayEstates:
            return .get
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
