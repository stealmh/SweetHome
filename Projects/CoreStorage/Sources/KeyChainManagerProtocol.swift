//
//  KeyChainManagerProtocol.swift
//  CoreStorage
//
//  Created by Claude on 10/21/25.
//

import Foundation

/// - KeyChain Manager Protocol
/// - KeyChain 저장소 접근을 추상화
public protocol KeyChainManagerProtocol: Sendable {
    func read(_ key: KeyChainKey) -> String?
    func save(_ key: KeyChainKey, value: String)
    func delete(_ key: KeyChainKey)
    func deleteAll()
    func contains(_ key: KeyChainKey) -> Bool
}
