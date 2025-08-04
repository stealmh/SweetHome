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
    
    // 토큰 재요청용 별도 ApiClient (인터셉터 없음)
    private lazy var refreshApiClient: ApiClient = {
        return ApiClient(network: NetworkService(interceptor: nil))
    }()
    
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
            
        case 403, 419:
            // 액세스 토큰 만료 - 토큰 갱신 시도
            logger.logTokenRefresh()
            print("🔄 TokenInterceptor: 419 에러 발생, 토큰 재요청 시작")
            
            Task {
                do {
                    guard let refreshToken = KeyChainManager.shared.read(.refreshToken) else {
                        print("❌ TokenInterceptor: RefreshToken이 없음")
                        completion(.doNotRetryWithError(SHError.networkError(.tokenExpired)))
                        return 
                    }
                    
                    print("🔄 TokenInterceptor: RefreshToken 존재, 토큰 재요청 API 호출")
                    let tokenResponse: ReIssueResponse = try await refreshApiClient.request(AuthEndpoint.refresh(refreshToken: refreshToken))
                    
                    print("✅ TokenInterceptor: 토큰 재요청 성공")
                    keyChainManager.save(.accessToken, value: tokenResponse.accessToken)
                    keyChainManager.save(.refreshToken, value: tokenResponse.refreshToken)
                    logger.logTokenRefreshSuccess()
                    
                    // 토큰 갱신 알림
                    NotificationCenter.default.post(name: NSNotification.Name("TokenRefreshed"), object: nil)
                    
                    completion(.retry)
                } catch {
                    print("❌ TokenInterceptor: 토큰 재요청 실패 - \(error)")
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
