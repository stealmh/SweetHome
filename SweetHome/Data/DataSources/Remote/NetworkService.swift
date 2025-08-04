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
    
    // 인터셉터를 옵셔널로 받는 생성자 (토큰 재요청용)
    init(interceptor: RequestInterceptor?) {
        self.session = Session(interceptor: interceptor)
    }
    
    func request<T: Decodable>(_ target: TargetType) async throws -> T {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: SHError.networkError(.unknown(statusCode: nil, message: "NetworkService가 해제되었습니다.")))
                return
            }
            
            do {
                let urlRequest = try target.asURLRequest()
                logger.logRequest(urlRequest)
                
                let dataRequest = session.request(urlRequest)
                
                dataRequest
                    .validate(statusCode: 200..<300)
                    .responseData { [weak self] response in
                        self?.handleResponse(response: response, continuation: continuation)
                    }
            } catch {
                continuation.resume(throwing: SHError.networkError(.unknown(statusCode: nil, message: "요청 생성 실패: \(error.localizedDescription)")))
            }
        }
    }
    
    func upload<T: Codable>(_ target: TargetType) async throws -> T {
        guard let multipartData = target.multipartData else {
            throw SHError.networkError(.unknown(statusCode: nil, message: "유효하지 않은 업로드 데이터입니다."))
        }
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: SHError.networkError(.unknown(statusCode: nil, message: "NetworkService가 해제되었습니다.")))
                return
            }
            
            let totalDataSize = multipartData.reduce(0) { $0 + $1.data.count }
            
            let uploadRequest = session.upload(
                multipartFormData: { formData in
                    multipartData.forEach { data in
                        if let fileName = data.fileName, let mimeType = data.mimeType {
                            formData.append(data.data, withName: data.name, fileName: fileName, mimeType: mimeType)
                        } else {
                            formData.append(data.data, withName: data.name)
                        }
                    }
                },
                to: target.url,
                method: target.method,
                headers: target.headers
            )
            
            // Log upload start
            if let urlRequest = uploadRequest.request {
                logger.logUploadStart(urlRequest, dataSize: totalDataSize)
            }
            
            uploadRequest
                .validate(statusCode: 200..<300)
                .responseData { [weak self] response in
                    // Log upload complete
                    if let httpResponse = response.response {
                        self?.logger.logUploadComplete(httpResponse)
                    }
                    
                    self?.handleResponse(response: response, continuation: continuation)
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleResponse<T: Decodable>(
        response: DataResponse<Data, AFError>,
        continuation: CheckedContinuation<T, Error>
    ) {
        // Log response
        if let httpResponse = response.response {
            logger.logResponse(httpResponse, data: response.data)
        }
        
        switch response.result {
        case .success(let data):
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                continuation.resume(returning: decodedData)
            } catch {
                let decodingError = SHError.networkError(.decodingError)
                logger.logError(decodingError, for: response.request)
                continuation.resume(throwing: decodingError)
            }
            
        case .failure(let error):
            logger.logError(error, for: response.request)
            
            guard let statusCode = response.response?.statusCode else {
                continuation.resume(throwing: SHError.networkError(.connectionFailed("네트워크 연결에 실패했습니다.")))
                return
            }
            
            if let data = response.data,
               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: errorResponse.message)))
            } else {
                continuation.resume(throwing: SHError.networkError(.serverError(statusCode: statusCode, message: "서버 오류가 발생했습니다. (코드: \(statusCode))")))
            }
        }
    }
}
