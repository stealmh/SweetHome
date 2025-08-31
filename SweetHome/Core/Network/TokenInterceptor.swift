//
//  TokenInterceptor.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

/// - HTTP 요청의 토큰 인증을 관리하는 Alamofire 인터셉터
final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor()
    /// - 토큰 상태 관리
    private let tokenManager = TokenManager()
    
    private init() {}
    
    /// - HTTP 요청에 액세스 토큰을 추가
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        Task {
            let adaptedRequest = await tokenManager.addAccessTokenToRequest(urlRequest)
            completion(.success(adaptedRequest))
        }
    }
    
    /// - HTTP 요청 실패 시 토큰 갱신을 통한 재시도
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        Task {
            guard let response = request.task?.response as? HTTPURLResponse else {
                completion(.doNotRetryWithError(error))
                return
            }
            /// - 모든 토큰 관련 로직을 TokenManager에 위임
            await tokenManager.handleRetryRequest(
                statusCode: response.statusCode,
                error: error,
                completion: completion
            )
        }
    }
}

