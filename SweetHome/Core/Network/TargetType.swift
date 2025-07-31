//
//  TargetType.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

protocol TargetType {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var body: Encodable? { get }
    var encoding: ParameterEncoding { get }
    var multipartData: [MultipartFormData]? { get }
}

extension TargetType {
    var url: String { return baseURL + path }
    
    var headers: [String: String]? { return ["Content-Type": "application/json"] }
    
    var parameters: [String: Any]? { return nil }
    
    var body: Encodable? { return nil }
    
    var encoding: ParameterEncoding { return JSONEncoding.default }
    
    var multipartData: [MultipartFormData]? { return nil }
}
