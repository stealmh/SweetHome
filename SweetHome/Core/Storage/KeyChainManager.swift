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
    
    private func contains(_ key: KeyChainKey) -> Bool {
        print("🗝️ '\(key)' 값이 포함되어 있는지 확인중 입니다.")
        guard let _ = controller.read(key) else { return false }
        return true
    }
    
    func read(_ key: KeyChainKey) -> String? {
        guard let data = controller.read(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func save(_ key: KeyChainKey, value: String) {
        let data = value.data(using: .utf8)
        
        contains(key)
        ? controller.update(data, key: key)
        : controller.create(data, key: key)
    }
    
    func deleteAll() {
        KeyChainKey.allCases.forEach { controller.delete($0) }
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
        print("🗝️ '\(key)' 항목을 새로 저장했습니다.")
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
        print("🗝️ '\(key)' 항목을 불러왔어요.")
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
        print("🗝️ '\(key)' 업데이트 성공!")
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
            print("🗝️ '\(key)' 항목이 없어 삭제하지 못했어요.")
            return
        }
        guard status == errSecSuccess else {
            return
        }
        print("🗝️ '\(key)' 항목을 삭제 했어요!")
    }
}
