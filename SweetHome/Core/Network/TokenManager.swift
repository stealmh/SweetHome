//
//  TokenManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/7/25.
//

import Foundation
import Alamofire

/// - 토큰 갱신과 관련된 상태 관리
actor TokenManager {
    /// - 요청 재시도 완료 핸들러 타입 정의
    typealias RequestRetryCompletion = (RetryResult) -> Void
    
    // MARK: - Properties
    private let keychainManager: KeyChainManagerProtocol
    private let refreshNetworkService: NetworkServiceProtocol
    /// - 토큰 갱신 진행 상태
    private var isRefreshing = false
    /// - 토큰 만료 상태
    private var isTokenExpired = false
    /// - 대기 중인 요청들의 완료 핸들러 배열
    private var pendingRequests: [RequestRetryCompletion] = []
    
    // MARK: - Initialization
    init(
        keychainManager: KeyChainManagerProtocol = KeyChainManager.shared,
        refreshNetworkService: NetworkServiceProtocol? = nil
    ) {
        self.keychainManager = keychainManager
        self.refreshNetworkService = refreshNetworkService ?? NetworkService(interceptor: nil)
    }
}
//MARK: - Public Method
extension TokenManager {
    /// - 현재 토큰 관리자의 상태를 반환
    func getState() -> (isRefreshing: Bool, isTokenExpired: Bool, pendingCount: Int) {
        return (isRefreshing, isTokenExpired, pendingRequests.count)
    }
    
    /// - 토큰 만료 상태를 설정
    func setTokenExpired(_ expired: Bool) {
        isTokenExpired = expired
    }
    
    /// - 토큰 만료 상태 확인
    func isExpired() -> Bool {
        return isTokenExpired
    }
    
    /// - 대기 중인 요청에 완료 핸들러 추가
    func addPendingRequest(_ completion: @escaping RequestRetryCompletion) {
        pendingRequests.append(completion)
    }
    
    /// - 토큰 갱신 시작 (이미 진행중이거나 토큰이 만료된 경우 실패)
    /// - 더 이상 사용하지 않음: handleTokenRefresh에서 원자적으로 처리
    @available(*, deprecated, message: "Use atomic check in handleTokenRefresh instead")
    func startRefresh() -> Bool {
        guard !isRefreshing && !isTokenExpired else {
            return false
        }
        isRefreshing = true
        return true
    }
    
    /// - 토큰 갱신을 완료하고 대기 중인 요청들의 완료 핸들러를 반환
    func finishRefresh(success: Bool) -> [RequestRetryCompletion] {
        let completions = pendingRequests
        isRefreshing = false
        pendingRequests.removeAll()

        if success {
            isTokenExpired = false
        }

        return completions
    }
    
    /// - 모든 대기 중인 요청을 취소하고 완료 핸들러를 반환
    func cancelAllRequests() -> [RequestRetryCompletion] {
        let completions = pendingRequests
        isRefreshing = false
        pendingRequests.removeAll()
        return completions
    }
    
    // MARK: - Request Handling
    
    /// - HTTP 요청에 액세스 토큰을 추가
    func addAccessTokenToRequest(_ urlRequest: URLRequest) -> URLRequest {
        var adaptedRequest = urlRequest
        
        if let accessToken = keychainManager.read(.accessToken) {
            adaptedRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        return adaptedRequest
    }
    
    /// - HTTP 응답 상태 코드에 따른 재시도 처리
    func handleRetryRequest(
        statusCode: Int,
        error: Error,
        completion: @escaping RequestRetryCompletion
    ) async {
        switch statusCode {
        case 419:
            /// - 액세스 토큰 만료 시 토큰 갱신 처리
            await handleTokenRefreshInternal(completion: completion)
        case 401, 403, 418:
            /// - 리프레시 토큰 만료 시 토큰 만료 처리
            let completions = await handleTokenExpired(keychainManager: keychainManager)
            
            Task.detached {
                let error = SHError.networkError(.refreshTokenExpired)
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
            
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
        default:
            /// - 기타 에러는 재시도하지 않음
            completion(.doNotRetryWithError(error))
        }
    }
    
    // MARK: - Token Business Logic

    /// - 내부 토큰 갱신 처리 (단일 진입점)
    private func handleTokenRefreshInternal(completion: @escaping RequestRetryCompletion) async {
        /// - 토큰이 이미 만료된 경우 즉시 실패 처리
        if isTokenExpired {
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            return
        }

        /// - 무조건 대기 큐에 추가
        addPendingRequest(completion)

        /// - 원자적 compare-and-swap 패턴으로 갱신 시작 체크
        if !isRefreshing {
            isRefreshing = true
            await performSingleTokenRefresh()
        }
    }

    /// - 단일 토큰 갱신 수행 (재진입 불가)
    private func performSingleTokenRefresh() async {
        guard let refreshToken = keychainManager.read(.refreshToken) else {
            await handleRefreshFailure(SHError.networkError(.tokenExpired))
            return
        }

        do {
            let tokenResponse: ReIssueResponse = try await refreshNetworkService.request(
                AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager)
            )

            keychainManager.save(.accessToken, value: tokenResponse.accessToken)
            keychainManager.save(.refreshToken, value: tokenResponse.refreshToken)

            await handleRefreshSuccess()

        } catch {
            await handleRefreshFailure(error)
        }
    }

    /// - 토큰 갱신을 처리하고 대기 중인 요청들을 관리 (외부 API용 - Deprecated)
    @available(*, deprecated, message: "Use handleTokenRefreshInternal instead")
    func handleTokenRefresh(
        completion: @escaping RequestRetryCompletion,
        keychainManager: KeyChainManagerProtocol,
        refreshNetworkService: NetworkServiceProtocol
    ) async {
        await handleTokenRefreshInternal(completion: completion)
    }
    
    /// - 토큰 만료 상태 처리
    func handleTokenExpired(keychainManager: KeyChainManagerProtocol) async -> [RequestRetryCompletion] {
        /// - 토큰 만료 상태 설정
        setTokenExpired(true)
        keychainManager.deleteAll()
        
        /// - 대기 중인 모든 요청 취소
        let completions = cancelAllRequests()
        
        /// - 메인 스레드에서 노티피케이션 발송
        Task { @MainActor in
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
        }
        
        return completions
    }
}
//MARK: - Private Method
private extension TokenManager {
    
    /// - 토큰 갱신 성공 처리
    func handleRefreshSuccess() async {
        let completions = finishRefresh(success: true)
        Task.detached { completions.forEach { $0(.retry) } }
    }
    
    /// - 토큰 갱신 실패 처리
    func handleRefreshFailure(_ error: Error) async {
        let isRefreshTokenExpired = isRefreshTokenError(error)
        
        if isRefreshTokenExpired {
            /// - 리프레시 토큰 만료 시
            setTokenExpired(true)
            let completions = cancelAllRequests()
            
            Task { @MainActor in
                NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
            }
            
            Task.detached {
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
        } else {
            /// - 일반적인 갱신 실패
            let completions = finishRefresh(success: false)
            
            Task.detached {
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
        }
    }
    
    /// - 리프레시 토큰 만료 에러 체크
    func isRefreshTokenError(_ error: Error) -> Bool {
        if let shError = error as? SHError,
           case .networkError(let networkError) = shError,
           case .refreshTokenExpired = networkError {
            return true
        }
        
        if let shError = error as? SHError,
           case .networkError(let networkError) = shError,
           case .serverError(let statusCode, _) = networkError,
           (statusCode == 418 || statusCode == 403) {
            return true
        }
        
        return false
    }
}
