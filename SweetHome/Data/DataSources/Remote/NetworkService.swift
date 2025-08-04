//
//  NetworkService.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ target: TargetType) async throws -> T
    func upload<T: Codable>(_ target: TargetType) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    private let session: Session
    private let logger = NetworkLogger.shared
    
    private init() {
        self.session = Session(interceptor: TokenInterceptor.shared)
    }
    
    func request<T: Decodable>(_ target: TargetType) async throws -> T {
        print(#function)
        return try await withCheckedThrowingContinuation { continuation in
            let dataRequest: DataRequest
            
            // Encodable body가 있으면 우선적으로 사용
            if let body = target.body {
                print("🔍 Using Encodable body: \(body)")
                do {
                    let jsonData = try JSONEncoder().encode(body)
                    print("🔍 JSON encoded data: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
                    var urlRequest = try URLRequest(url: target.url, method: target.method)
                    urlRequest.httpBody = jsonData
                    
                    // 기본 헤더 설정
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // 추가 헤더 설정
                    if let headers = target.headers {
                        print("🔍 Setting additional headers: \(headers)")
                        for (key, value) in headers {
                            urlRequest.setValue(value, forHTTPHeaderField: key)
                        }
                    }
                    
                    print("🔍 Created URLRequest: \(urlRequest)")
                    print("🔍 URLRequest body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
                    
                    // URLRequest 직접 로깅
                    logger.logRequest(urlRequest)
                    
                    dataRequest = session.request(urlRequest)
                } catch {
                    continuation.resume(throwing: SHError.networkError(.decodingError))
                    return
                }
            } else {
                // 기존 parameters 방식 사용
                dataRequest = session.request(
                    target.url,
                    method: target.method,
                    parameters: target.parameters,
                    encoding: target.encoding,
                    headers: target.headers != nil ? HTTPHeaders(target.headers!) : nil
                )
            }
            
            // Log request (for parameters-based requests only)
            if target.body == nil {
                if let urlRequest = dataRequest.request {
                    logger.logRequest(urlRequest)
                }
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
                            let decodingError = SHError.networkError(.decodingError)
                            self.logger.logError(decodingError, for: dataRequest.request)
                            continuation.resume(throwing: decodingError)
                        }
                    case .failure(let error):
                        /// 로그를 통한 에러 방출
                        self.logger.logError(error, for: dataRequest.request)
                        
                        /// 🚨 Case [1]. `statusCode`를 받을 수 없을 때
                        guard let statusCode = response.response?.statusCode
                        else { continuation.resume(throwing: SHError.networkError(.connectionFailed("네트워크 연결에 실패했습니다."))); return }
                        
                        /// 🚨 Case [2]. 파싱에 실패했을 때
                        guard let data = response.data,
                              let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                        else { continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: "서버 오류가 발생했습니다. (코드: \(statusCode))"))); return }
                        
                        continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: errorResponse.message)))
                    }
                }
        }
    }
    
    func upload<T: Codable>(_ target: TargetType) async throws -> T {
        guard let multipartData = target.multipartData else {
            throw SHError.networkError(.unknown(statusCode: nil, message: "유효하지 않은 업로드 데이터입니다."))
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
                            let decodingError = SHError.networkError(.decodingError)
                            self.logger.logError(decodingError, for: uploadRequest.request)
                            continuation.resume(throwing: decodingError)
                        }
                    case .failure(let error):
                        self.logger.logError(error, for: uploadRequest.request)
                        if let statusCode = response.response?.statusCode {
                            if let data = response.data,
                               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: errorResponse.message)))
                            } else {
                                continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: "서버 오류가 발생했습니다. (코드: \(statusCode))")))
                            }
                        } else {
                            continuation.resume(throwing: SHError.networkError(.connectionFailed("네트워크 연결에 실패했습니다.")))
                        }
                    }
                }
        }
    }
}
