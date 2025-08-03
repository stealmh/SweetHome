//
//  AuthTokenManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

final class AuthTokenManager {
    static let shared = AuthTokenManager()
    
    private let keyChainManager = KeyChainManager.shared
    private var cachedAccessToken: String?
    private var cachedSesacKey: String?
    
    private init() {
        // 앱 시작 시 토큰 캐시
        loadTokensFromKeyChain()
        
        // 토큰 갱신 Notification 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRefresh),
            name: NSNotification.Name("TokenRefreshed"),
            object: nil
        )
        
        // 토큰 만료 Notification 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenExpired),
            name: .refreshTokenExpired,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    var accessToken: String? {
        if cachedAccessToken == nil {
            loadTokensFromKeyChain()
        }
        return cachedAccessToken
    }
    
    var sesacKey: String {
        if cachedSesacKey == nil {
            cachedSesacKey = APIConstants.sesacKey
        }
        return cachedSesacKey ?? ""
    }
    
    func refreshCache() {
        loadTokensFromKeyChain()
    }
    
    func clearCache() {
        cachedAccessToken = nil
        cachedSesacKey = nil
    }
    
    // MARK: - Private Methods
    private func loadTokensFromKeyChain() {
        cachedAccessToken = keyChainManager.read(.accessToken)
        cachedSesacKey = APIConstants.sesacKey
    }
    
    @objc private func handleTokenRefresh() {
        refreshCache()
    }
    
    @objc private func handleTokenExpired() {
        clearCache()
    }
}
