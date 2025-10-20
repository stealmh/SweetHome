//
//  StorageProtocols.swift
//  Auth
//
//  Created by 김민호 on 10/20/25.
//

import Foundation

/// - KeyChain Key 정의
public enum KeyChainKey: String {
    case accessToken = "accessToken"
    case refreshToken = "refreshToken"
    case userID = "userID"
}

/// - KeyChain Manager Protocol
public protocol KeyChainManagerProtocol: Sendable {
    func read(_ key: KeyChainKey) -> String?
    func save(_ key: KeyChainKey, value: String)
    func delete(_ key: KeyChainKey)
    func deleteAll()
    func contains(_ key: KeyChainKey) -> Bool
}
