//
//  KeyChainController.swift
//  CoreStorage
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

/// - KeyChain Controller Protocol
public protocol KeyChainControllerProtocol: Sendable {
    func create(_ data: Data?, key: KeyChainKey)
    func read(_ key: KeyChainKey) -> Data?
    func update(_ data: Data?, key: KeyChainKey)
    func delete(_ key: KeyChainKey)
}

/// - KeyChain Controller 구현체
/// - iOS KeyChain API를 직접 호출
public struct KeyChainController: KeyChainControllerProtocol {
    public let service: String

    public init(service: String = "SweetHome") {
        self.service = service
    }

    public func create(_ data: Data?, key: KeyChainKey) {
        guard let data = data else { return }

        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData: data
        ]

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else { return }
    }

    // MARK: Read Item
    public func read(_ key: KeyChainKey) -> Data? {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    // MARK: Update Item
    public func update(_ data: Data?, key: KeyChainKey) {
        guard let data else { return }

        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
        ]
        let attributes: NSDictionary = [kSecValueData: data]

        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else { return }
    }

    // MARK: Delete Item
    public func delete(_ key: KeyChainKey) {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]

        let status = SecItemDelete(query)
        guard status != errSecItemNotFound else { return }
        guard status == errSecSuccess else { return }
    }
}
