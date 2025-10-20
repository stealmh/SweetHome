//
//  NetworkProtocols.swift
//  Auth
//
//  Created by 김민호 on 10/20/25.
//

import Foundation
import RxSwift
import Alamofire

/// - HTTP Task 정의
public enum HTTPTask {
    case requestPlain
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
    case requestJSONEncodable(Encodable)
}

/// - API Endpoint 정의를 위한 Protocol
public protocol TargetType: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var task: HTTPTask { get }
    var timeout: TimeInterval { get }
}

/// - Default Implementations
extension TargetType {
    public var url: URL {
        guard let url = URL(string: baseURL + path) else {
            fatalError("Invalid URL: \(baseURL + path)")
        }
        return url
    }

    public var headers: HTTPHeaders? { return nil }
    public var timeout: TimeInterval { return 30.0 }

    public func asURLRequest() throws -> URLRequest {
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
        }

        return request
    }
}

/// - API Client Protocol
public protocol ApiClientProtocol {
    func requestObservable<T: Decodable>(_ endpoint: TargetType) -> Observable<T>
}
