//
//  TokenManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/7/25.
//

import Foundation

/// - 토큰 갱신과 관련된 상태 관리
actor TokenManager {
    /// - 토큰 갱신 진행 상태
    private var isRefreshing = false
    /// - 토큰 만료 상태
    private var isTokenExpired = false
    /// - 대기 중인 요청들의 완료 핸들러 배열
    private var pendingRequests: [TokenInterceptor.RequestRetryCompletion] = []
    
    /// - 현재 토큰 관리자의 상태를 반환한다
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
    func addPendingRequest(_ completion: @escaping TokenInterceptor.RequestRetryCompletion) {
        pendingRequests.append(completion)
    }
    
    /// - 토큰 갱신 시작 (이미 진행중이거나 토큰이 만료된 경우 실패)
    func startRefresh() -> Bool {
        guard !isRefreshing && !isTokenExpired else {
            return false
        }
        isRefreshing = true
        return true
    }
    
    /// - 토큰 갱신을 완료하고 대기 중인 요청들의 완료 핸들러를 반환
    func finishRefresh(success: Bool) -> [TokenInterceptor.RequestRetryCompletion] {
        let completions = pendingRequests
        isRefreshing = false
        pendingRequests.removeAll()
        
        if success {
            isTokenExpired = false
        }
        
        return completions
    }
    
    /// - 모든 대기 중인 요청을 취소하고 완료 핸들러를 반환
    func cancelAllRequests() -> [TokenInterceptor.RequestRetryCompletion] {
        let completions = pendingRequests
        isRefreshing = false
        pendingRequests.removeAll()
        return completions
    }
}
