//
//  TargetType.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

enum HTTPTask {
    case requestPlain
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
    case requestJSONEncodable(Encodable)
    case uploadMultipart([MultipartFormData])
}

protocol TargetType: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var task: HTTPTask { get }
    var timeout: TimeInterval { get }
}

// MARK: - Default Implementations
extension TargetType {
    var url: URL {
        guard let url = URL(string: baseURL + path) else {
            fatalError("Invalid URL: \(baseURL + path)")
        }
        return url
    }
    
    var headers: HTTPHeaders? { return nil }
    
    var timeout: TimeInterval { return 30.0 }
}

// MARK: - URLSession 조립
extension TargetType {
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        headers?.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        switch task {
        case .requestPlain:
            break
            
        case .requestParameters(let parameters, let encoding):
            request = try encoding.encode(request, with: parameters)
            
        case .requestJSONEncodable(let encodable):
            request.httpBody = try JSONEncoder().encode(encodable)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        case .uploadMultipart(_):
            break
        }
        
        return request
    }
}

// MARK: - HTTPTask Extension for NetworkService compatibility
extension TargetType {
    var multipartData: [MultipartFormData]? {
        switch task {
        case .uploadMultipart(let data):
            return data
        default:
            return nil
        }
    }
}
