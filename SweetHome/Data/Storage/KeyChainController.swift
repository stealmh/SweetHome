//
//  KeyChainController.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

protocol KeyChainControllerProtocol: Sendable {
    func create(_ data: Data?, key: KeyChainKey)
    func read(_ key: KeyChainKey) -> Data?
    func update(_ data: Data?, key: KeyChainKey)
    func delete(_ key: KeyChainKey)
}

struct KeyChainController: KeyChainControllerProtocol {
    let service: String = "SweetHome"

    func create(_ data: Data?, key: KeyChainKey) {
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
    func read(_ key: KeyChainKey) -> Data? {
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
    func update(_ data: Data?, key: KeyChainKey) {
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
    func delete(_ key: KeyChainKey) {
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
