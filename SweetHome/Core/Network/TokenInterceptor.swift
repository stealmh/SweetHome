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
    
    // 동시 토큰 갱신 방지를 위한 플래그
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    private let lock = NSLock()
    
    // 대기 중인 요청들을 위한 타입 정의
    typealias RequestRetryCompletion = (RetryResult) -> Void
    
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
        case 403, 419:
            /// - 액세스 토큰 만료 - 토큰 갱신 시도
            handleTokenRefresh(completion: completion)
            
        case 418:
            /// - 리프레시 토큰 만료 - 로그인 화면으로 이동
            handleTokenExpired()
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            
        default:
            completion(.doNotRetryWithError(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTokenExpired() {
        logger.logTokenRefreshTokenExpired()
        keyChainManager.deleteAll()
        logger.logTokenCleared()
        
        // 진행 중인 토큰 갱신 취소
        lock.lock()
        isRefreshing = false
        requestsToRetry.removeAll()
        lock.unlock()
        
        // Notification을 통해 로그인 화면 이동 요청
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
        }
    }
    
    private func handleTokenRefresh(completion: @escaping RequestRetryCompletion) {
        lock.lock()
        
        /// - 이미 토큰 갱신 중이면 대기 큐에 추가
        if isRefreshing {
            requestsToRetry.append(completion)
            lock.unlock()
            return
        }
        
        /// - 토큰 갱신 시작
        isRefreshing = true
        lock.unlock()
        logger.logTokenRefresh()
        
        Task {
            do {
                guard let refreshToken = keyChainManager.read(.refreshToken) else {
                    await handleRefreshFailure(SHError.networkError(.tokenExpired))
                    return
                }
                
                let tokenResponse: ReIssueResponse = try await refreshApiClient.request(AuthEndpoint.refresh(refreshToken: refreshToken))
                keyChainManager.save(.accessToken, value: tokenResponse.accessToken)
                keyChainManager.save(.refreshToken, value: tokenResponse.refreshToken)
                logger.logTokenRefreshSuccess()
                
                /// - 토큰 갱신 알림
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("TokenRefreshed"), object: nil)
                }
                
                await handleRefreshSuccess()
                
            } catch {
                logger.logTokenRefreshFailed(error)
                keyChainManager.deleteAll()
                logger.logTokenCleared()
                await handleRefreshFailure(error)
            }
        }
    }
    
    @MainActor
    private func handleRefreshSuccess() {
        lock.lock()
        isRefreshing = false

        let retryCompletions = requestsToRetry
        requestsToRetry.removeAll()
        lock.unlock()
        
        retryCompletions.forEach { $0(.retry) }
    }
    
    @MainActor
    private func handleRefreshFailure(_ error: Error) {
        lock.lock()
        isRefreshing = false
        
        let retryCompletions = requestsToRetry
        requestsToRetry.removeAll()
        lock.unlock()
        
        retryCompletions.forEach { $0(.doNotRetryWithError(error)) }
    }
}
