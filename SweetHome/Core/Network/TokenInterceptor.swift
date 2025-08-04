//
//  TokenInterceptor.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor()
    private let keyChainManager = KeyChainManager.shared
    private let logger = NetworkLogger.shared
    
    private init() {}
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        if let accessToken = keyChainManager.read(.accessToken) {
            adaptedRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(adaptedRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        switch response.statusCode {
        case 418:
            // 리프레시 토큰 만료 - 로그인 화면으로 이동
            logger.logTokenRefreshTokenExpired()
            keyChainManager.deleteAll()
            logger.logTokenCleared()
            
            // Notification을 통해 로그인 화면 이동 요청
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
            
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            
        case 419:
            // 액세스 토큰 만료 - 토큰 갱신 시도
            logger.logTokenRefresh()
            
            Task {
                do {
                    guard let refreshToken = KeyChainManager.shared.read(.refreshToken) else { 
                        completion(.doNotRetryWithError(SHError.networkError(.tokenExpired)))
                        return 
                    }
                    let apiClient = ApiClient.shared
                    let tokenResponse: ReIssueResponse = try await apiClient.request(AuthEndpoint.refresh(refreshToken: refreshToken))
                    
                    keyChainManager.save(.accessToken, value: tokenResponse.accessToken)
                    keyChainManager.save(.refreshToken, value: tokenResponse.refreshToken)
                    logger.logTokenRefreshSuccess()
                    
                    // 토큰 갱신 알림
                    NotificationCenter.default.post(name: NSNotification.Name("TokenRefreshed"), object: nil)
                    
                    completion(.retry)
                } catch {
                    logger.logTokenRefreshFailed(error)
                    keyChainManager.deleteAll()
                    logger.logTokenCleared()
                    completion(.doNotRetryWithError(error))
                }
            }
            
        default:
            completion(.doNotRetryWithError(error))
        }
    }
}
