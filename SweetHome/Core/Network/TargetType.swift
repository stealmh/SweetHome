//
//  TargetType.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

protocol TargetType: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var body: Encodable? { get }
    var parameters: [String: Any]? { get }
    var encoding: ParameterEncoding { get }
    var multipartData: [MultipartFormData]? { get }
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
    
    var headers: HTTPHeaders? {  return HTTPHeaders(["Content-Type": "application/json"]) }
    
    var body: Encodable? { return nil }
    
    var parameters: [String: Any]? { return nil }
    
    var encoding: ParameterEncoding { return body != nil ? JSONEncoding.default : URLEncoding.default }
    
    var multipartData: [MultipartFormData]? { return nil }
    
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
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    
        else if let parameters = parameters {
            request = try encoding.encode(request, with: parameters)
        }
        
        return request
    }
}
