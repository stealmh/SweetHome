//
//  KeyChainManager.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

final class KeyChainManager: Sendable {
    static let shared = KeyChainManager()
    private let controller = KeychainController()
    
    private init() {}
    
    func read(_ key: KeyChainKey) -> String? {
        guard let data = controller.read(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func save(_ key: KeyChainKey, value: String) {
        let data = value.data(using: .utf8)
        
        controller.read(key) != nil
        ? controller.update(data, key: key)
        : controller.create(data, key: key)
    }
    
    func deleteAll() {
        controller.delete(.accessToken)
        controller.delete(.refreshToken)
    }
}

private struct KeychainController: Sendable {
    let service: String = "SweetHome"

    func create(_ data: Data?, key: KeyChainKey) {
        guard let data = data else {
            print("🗝️ '\(key)' 값이 없어요.")
            return
        }

        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData: data
        ]

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            print("🗝️ '\(key)' 상태 = \(status)")
            return
        }
        print("🗝️ '\(key)' 성공!")
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
        guard status != errSecItemNotFound else {
            print("🗝️ '\(key)' 항목을 찾을 수 없어요.")
            return nil
        }
        guard status == errSecSuccess else { return nil }
        print("🗝️ '\(key)' 성공!")
        return result as? Data
    }

    // MARK: Update Item
    func update(_ data: Data?, key: KeyChainKey) {
        guard let data = data else {
            print("🗝️ '\(key)' 값이 없어요.")
            return
        }

        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
        ]
        let attributes: NSDictionary = [kSecValueData: data]

        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else {
            print("🗝️ '\(key)' 상태 = \(status)")
            return
        }
        print("🗝️ '\(key)' 성공!")
    }

    // MARK: Delete Item
    func delete(_ key: KeyChainKey) {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]

        let status = SecItemDelete(query)
        guard status != errSecItemNotFound else {
            print("🗝️ '\(key)' 항목을 찾을 수 없어요.")
            return
        }
        guard status == errSecSuccess else {
            return
        }
        print("🗝️ '\(key)' 성공!")
    }
}
