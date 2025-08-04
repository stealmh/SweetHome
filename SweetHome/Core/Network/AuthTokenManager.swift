//
//  AuthTokenManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

final class AuthTokenManager {
    static let shared = AuthTokenManager()
    
    private let keychainManager: KeyChainManagerProtocol
    private var cachedAccessToken: String?
    private var cachedSesacKey: String?
    
    init(keychainManager: KeyChainManagerProtocol = KeyChainManager.shared) {
        self.keychainManager = keychainManager
        
        loadTokensFromKeyChain()
        
        // 토큰 만료 Notification 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenExpired),
            name: .refreshTokenExpired,
            object: nil
        )
    }
    
    // Convenience initializer for shared instance
    private convenience init() {
        self.init(keychainManager: KeyChainManager.shared)
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
        cachedAccessToken = keychainManager.read(.accessToken)
        cachedSesacKey = APIConstants.sesacKey
    }
    
    @objc private func handleTokenExpired() {
        clearCache()
    }
}
