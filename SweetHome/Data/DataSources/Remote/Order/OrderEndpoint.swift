//
//  OrderEndpoint.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import Foundation
import Alamofire

enum OrderEndpoint: TargetType {
    case order(body: OrderRequest)
}

extension OrderEndpoint {
    var baseURL: String { return APIConstants.baseURL }
    
    var path: String {
        switch self {
        case .order:
            return "/v1/orders"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .order:
            return .post
        }
    }
    
    var task: HTTPTask {
        switch self {
        case let .order(model):
            return .requestJSONEncodable(model)
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
