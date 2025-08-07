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
    
    /// - 키체인 관리자 인스턴스
    private let keychainManager: KeyChainManagerProtocol
    /// - 토큰 상태를 관리하는 액터 인스턴스
    private let tokenManager = TokenManager()
    
    /// - 요청 재시도 완료 핸들러 타입 정의
    typealias RequestRetryCompletion = (RetryResult) -> Void
    
    /// - 토큰 갱신 전용 네트워크 서비스 (인터셉터 없음)
    private let refreshNetworkService = NetworkService(interceptor: nil)
    
    init(keychainManager: KeyChainManagerProtocol = KeyChainManager.shared) {
        self.keychainManager = keychainManager
    }
    
    /// - 공유 인스턴스를 위한 편의 이니셜라이저
    private convenience init() {
        self.init(keychainManager: KeyChainManager.shared)
    }
    
    /// - HTTP 요청에 액세스 토큰을 추가한다
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        if let accessToken = keychainManager.read(.accessToken) {
            adaptedRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(adaptedRequest))
    }
    
    /// - HTTP 요청 실패 시 토큰 갱신을 통한 재시도를 처리한다
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        Task {
            /// - 토큰이 이미 만료된 경우 즉시 실패 처리
            let isExpired = await tokenManager.isExpired()
            if isExpired {
                completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
                return
            }
            
            guard let response = request.task?.response as? HTTPURLResponse else {
                completion(.doNotRetryWithError(error))
                return
            }
            
            switch response.statusCode {
            case 419:
                /// - 액세스 토큰 만료 시 토큰 갱신을 시도한다
                await handleTokenRefresh(completion: completion)
            case 403, 418:
                /// - 리프레시 토큰 만료 시 로그인 화면으로 이동한다
                await handleTokenExpired()
                completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            default:
                /// - 기타 에러는 재시도하지 않는다
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

extension TokenInterceptor {
    /// - 토큰 만료 상태를 처리하고 로그인 화면으로 이동을 위한 노티피케이션을 발송한다
    private func handleTokenExpired() async {
        /// - 토큰 만료 상태 설정 및 키체인에서 모든 토큰 삭제
        await tokenManager.setTokenExpired(true)
        keychainManager.deleteAll()
        
        /// - 대기 중인 모든 요청을 취소한다
        let completions = await tokenManager.cancelAllRequests()
        
        /// - 모든 대기 중인 요청에 실패 응답을 전달한다
        Task.detached {
            let error = SHError.networkError(.refreshTokenExpired)
            completions.forEach { $0(.doNotRetryWithError(error)) }
        }
        
        /// - 메인 스레드에서 토큰 만료 노티피케이션을 발송한다
        Task { @MainActor in
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
        }
    }
    
    /// - 토큰 갱신을 처리하고 대기 중인 요청들을 관리한다
    private func handleTokenRefresh(completion: @escaping RequestRetryCompletion) async {
        /// - 토큰이 이미 만료된 경우 즉시 실패 처리
        let isExpired = await tokenManager.isExpired()
        if isExpired {
            completion(.doNotRetryWithError(SHError.networkError(.refreshTokenExpired)))
            return
        }
        
        /// - 현재 요청을 대기 큐에 추가한다
        await tokenManager.addPendingRequest(completion)
        
        /// - 토큰 갱신을 시작할 수 있는지 확인하고 실행한다
        let canStartRefresh = await tokenManager.startRefresh()
        if canStartRefresh {
            await performTokenRefresh()
        }
        /// - 이미 갱신 중인 경우 대기 큐에 추가만 하고 종료
    }
    
    /// - 실제 토큰 갱신 네트워크 요청을 수행한다
    private func performTokenRefresh() async {
        do {
            /// - 키체인에서 리프레시 토큰을 읽어온다
            guard let refreshToken = keychainManager.read(.refreshToken) else {
                await handleRefreshFailure(SHError.networkError(.tokenExpired))
                return
            }
            
            /// - 토큰 갱신 API를 호출한다
            let tokenResponse: ReIssueResponse = try await refreshNetworkService.request(
                AuthEndpoint.refresh(refreshToken: refreshToken, keychainManager: keychainManager)
            )
            
            /// - 새로운 토큰들을 키체인에 저장한다
            keychainManager.save(.accessToken, value: tokenResponse.accessToken)
            keychainManager.save(.refreshToken, value: tokenResponse.refreshToken)
            
            await handleRefreshSuccess()
            
        } catch {
            await handleRefreshFailure(error)
        }
    }
    
    /// - 토큰 갱신 성공을 처리하고 대기 중인 요청들을 재시도한다
    private func handleRefreshSuccess() async {
        /// - 토큰 갱신 완료 처리 및 대기 중인 요청들을 가져온다
        let completions = await tokenManager.finishRefresh(success: true)
        
        /// - 모든 대기 중인 요청을 재시도한다
        Task.detached {
            completions.forEach { $0(.retry) }
        }
    }
    
    /// - 토큰 갱신 실패를 처리하고 적절한 후속 조치를 취한다
    private func handleRefreshFailure(_ error: Error) async {
        let isRefreshTokenExpired = isRefreshTokenError(error)
        
        if isRefreshTokenExpired {
            /// - 리프레시 토큰 만료 시 토큰 만료 상태 설정 및 키체인 삭제
            await tokenManager.setTokenExpired(true)
            keychainManager.deleteAll()
            
            let completions = await tokenManager.cancelAllRequests()
            
            /// - 토큰 만료 노티피케이션 발송
            Task { @MainActor in
                NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)
            }
            
            /// - 모든 대기 중인 요청을 실패 처리
            Task.detached {
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
        } else {
            /// - 일반적인 토큰 갱신 실패 처리
            let completions = await tokenManager.finishRefresh(success: false)
            
            Task.detached {
                completions.forEach { $0(.doNotRetryWithError(error)) }
            }
        }
    }
    
    /// - 에러가 리프레시 토큰 만료 관련 에러인지 확인한다
    private func isRefreshTokenError(_ error: Error) -> Bool {
        /// - SHError.networkError(.refreshTokenExpired) 타입 체크
        if let shError = error as? SHError,
           case .networkError(let networkError) = shError,
           case .refreshTokenExpired = networkError {
            return true
        }
        
        /// - HTTP 418/403 상태 코드 체크 (리프레시 토큰 만료)
        if let shError = error as? SHError,
           case .networkError(let networkError) = shError,
           case .serverError(let statusCode, _) = networkError,
           (statusCode == 418 || statusCode == 403) {
            return true
        }
        
        return false
    }
}
