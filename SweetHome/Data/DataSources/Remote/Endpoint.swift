//
//  Endpoint.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

enum APIEndpoint {
    case users
    case user(id: Int)
    case uploadImage(data: Data, fileName: String)
}

extension APIEndpoint: TargetType {
    var baseURL: String {
        //TODO: 실 요청 URL로 교체해야 함
        return "https://jsonplaceholder.typicode.com"
    }
    
    var path: String {
        switch self {
        case .users:
            return "/users"
        case .user(let id):
            return "/users/\(id)"
        case .uploadImage:
            return "/upload"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .users, .user:
            return .get
        case .uploadImage:
            return .post
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .uploadImage:
            return ["Content-Type": "multipart/form-data"]
        default:
            return ["Content-Type": "application/json"]
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .uploadImage: return URLEncoding.default
        default:           return JSONEncoding.default
        }
    }
    
    var multipartData: [MultipartFormData]? {
        switch self {
        case .uploadImage(let data, let fileName):
            return [MultipartFormData(data: data, name: "file", fileName: fileName, mimeType: "image/jpeg")]
        default:
            return nil
        }
    }
}
