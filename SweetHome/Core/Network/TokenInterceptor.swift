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
    
    private let keychainManager: KeyChainManagerProtocol
    
    // 동시성 제어를 위한 직렬 큐
    private let tokenRefreshQueue = DispatchQueue(label: "com.sweethome.token-refresh", qos: .userInitiated)
    
    // 토큰 갱신 상태 관리
    private var isRefreshing = false
    private var pendingRequests: [RequestRetryCompletion] = []
    
    // 대기 중인 요청들을 위한 타입 정의
    typealias RequestRetryCompletion = (RetryResult) -> Void
    
    // 토큰 재요청용 별도 NetworkService (인터셉터 없음)
    private let refreshNetworkService = NetworkService(interceptor: nil)
    
    init(keychainManager: KeyChainManagerProtocol = KeyChainManager.shared) {
        self.keychainManager = keychainManager
    }
    
    // Convenience initializer for shared instance
    private convenience init() {
        self.init(keychainManager: KeyChainManager.shared)
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        if let accessToken = keychainManager.read(.accessToken) {
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
        /// - 액세스 토큰 만료 - 토큰 갱신 시도
        case 419:
            handleTokenRefresh(completion: completion)
        /// - 리프레시 토큰 만료 - 로그인 화면으로 이동
        case 403, 418:
            handleTokenExpired()
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            
        default:
            completion(.doNotRetryWithError(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTokenExpired() {
        keychainManager.deleteAll()
        
        // 진행 중인 토큰 갱신 취소 및 대기 중인 요청들 정리
        tokenRefreshQueue.async { [weak self] in
            guard let self = self else { return }
            
            let completions = self.pendingRequests
            self.isRefreshing = false
            self.pendingRequests.removeAll()
            
            // 모든 대기 중인 요청에 실패 응답
            DispatchQueue.global(qos: .userInitiated).async {
                let error = SHError.networkError(.refreshTokenExpired)
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
        }
    }
    
    private func handleTokenRefresh(completion: @escaping RequestRetryCompletion) {
        tokenRefreshQueue.async { [weak self] in
            guard let self = self else { 
                completion(.doNotRetryWithError(SHError.networkError(.unknown(statusCode: nil, message: "TokenInterceptor 해제됨"))))
                return 
            }
            
            /// - 현재 요청을 대기 큐에 추가
            self.pendingRequests.append(completion)
            
            /// - 이미 토큰 갱신 중이면 추가 작업 없이 대기
            guard !self.isRefreshing else { return }
            
            /// - 토큰 갱신 시작
            self.isRefreshing = true
            
            Task { [weak self] in
                await self?.performTokenRefresh()
            }
        }
    }
    
    private func performTokenRefresh() async {
        do {
            guard let refreshToken = keychainManager.read(.refreshToken) else {
                await handleRefreshFailure(SHError.networkError(.tokenExpired))
                return
            }
            
            let tokenResponse: ReIssueResponse = try await refreshNetworkService.request(AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager))
            
            keychainManager.save(.accessToken, value: tokenResponse.accessToken)
            keychainManager.save(.refreshToken, value: tokenResponse.refreshToken)
            
            await handleRefreshSuccess()
            
        } catch {
            await handleRefreshFailure(error)
        }
    }
    
    private func handleRefreshSuccess() async {
        await withCheckedContinuation { continuation in
            tokenRefreshQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let completions = self.pendingRequests
                self.isRefreshing = false
                self.pendingRequests.removeAll()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    completions.forEach { $0(.retry) }
                }
                
                continuation.resume()
            }
        }
    }
    
    private func handleRefreshFailure(_ error: Error) async {
        let isRefreshTokenExpired = { () -> Bool in
            if let shError = error as? SHError,
               case .networkError(let networkError) = shError,
               case .refreshTokenExpired = networkError {
                return true
            }
            return false
        }()
        
        await withCheckedContinuation { continuation in
            tokenRefreshQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let completions = self.pendingRequests
                self.isRefreshing = false
                self.pendingRequests.removeAll()
                
                if isRefreshTokenExpired {
                    self.keychainManager.deleteAll()
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
                    }
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    completions.forEach { $0(.doNotRetryWithError(error)) }
                }
                
                continuation.resume()
            }
        }
    }
}
