//
//  NetworkService.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

protocol NetworkServiceProtocol {
    func request<T: Codable>(_ target: TargetType) async throws -> T
    func upload<T: Codable>(_ target: TargetType) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    private let session: Session
    private let logger = NetworkLogger.shared
    
    private init() {
        self.session = Session(interceptor: TokenInterceptor.shared)
    }
    
    func request<T: Codable>(_ target: TargetType) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let dataRequest = session.request(
                target.url,
                method: target.method,
                parameters: target.parameters,
                encoding: target.encoding,
                headers: target.headers != nil ? HTTPHeaders(target.headers!) : nil
            )
            
            // Log request
            if let urlRequest = dataRequest.request {
                logger.logRequest(urlRequest)
            }
            
            dataRequest
                .validate(statusCode: 200..<300)
                .responseData { response in
                    // Log response
                    if let httpResponse = response.response {
                        self.logger.logResponse(httpResponse, data: response.data)
                    }
                    
                    switch response.result {
                    case .success(let data):
                        do {
                            let decodedData = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(returning: decodedData)
                        } catch {
                            self.logger.logError(NetworkError.decodingError, for: dataRequest.request)
                            continuation.resume(throwing: NetworkError.decodingError)
                        }
                    case .failure(let error):
                        self.logger.logError(error, for: dataRequest.request)
                        if let statusCode = response.response?.statusCode {
                            continuation.resume(throwing: NetworkError.serverError(statusCode))
                        } else {
                            continuation.resume(throwing: NetworkError.unknown)
                        }
                    }
                }
        }
    }
    
    func upload<T: Codable>(_ target: TargetType) async throws -> T {
        guard let multipartData = target.multipartData else {
            throw NetworkError.invalidURL
        }
        
        // Calculate total data size for logging
        let totalDataSize = multipartData.reduce(0) { $0 + $1.data.count }
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadRequest = session.upload(
                multipartFormData: { formData in
                    for data in multipartData {
                        if let fileName = data.fileName, let mimeType = data.mimeType {
                            formData.append(data.data, withName: data.name, fileName: fileName, mimeType: mimeType)
                        } else {
                            formData.append(data.data, withName: data.name)
                        }
                    }
                },
                to: target.url,
                method: target.method,
                headers: target.headers != nil ? HTTPHeaders(target.headers!) : nil
            )
            
            // Log upload start
            if let urlRequest = uploadRequest.request {
                logger.logUploadStart(urlRequest, dataSize: totalDataSize)
            }
            
            uploadRequest
                .validate(statusCode: 200..<300)
                .responseData { response in
                    // Log upload complete
                    if let httpResponse = response.response {
                        self.logger.logUploadComplete(httpResponse)
                    }
                    
                    switch response.result {
                    case .success(let data):
                        do {
                            let decodedData = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(returning: decodedData)
                        } catch {
                            self.logger.logError(NetworkError.decodingError, for: uploadRequest.request)
                            continuation.resume(throwing: NetworkError.decodingError)
                        }
                    case .failure(let error):
                        self.logger.logError(error, for: uploadRequest.request)
                        if let statusCode = response.response?.statusCode {
                            continuation.resume(throwing: NetworkError.serverError(statusCode))
                        } else {
                            continuation.resume(throwing: NetworkError.unknown)
                        }
                    }
                }
        }
    }
}
