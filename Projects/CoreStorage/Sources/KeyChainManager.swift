//
//  KeyChainManager.swift
//  CoreStorage
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

/// - Thread-Safe KeychainManager 구현체
public final class KeyChainManager: KeyChainManagerProtocol {
    public static let shared = KeyChainManager()

    private let controller: KeyChainControllerProtocol
    private let keychainQueue: DispatchQueue

    public init(controller: KeyChainControllerProtocol = KeyChainController()) {
        self.controller = controller
        self.keychainQueue = DispatchQueue(
            label: "com.sweethome.keychain",
            qos: .userInitiated
        )
    }

    public func contains(_ key: KeyChainKey) -> Bool {
        return keychainQueue.sync {
            print("🗝️ '\(key)' 값이 포함되어 있는지 확인중 입니다.")
            return controller.read(key) != nil
        }
    }

    public func read(_ key: KeyChainKey) -> String? {
        return keychainQueue.sync {
            guard let data = controller.read(key) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    public func save(_ key: KeyChainKey, value: String) {
        keychainQueue.sync {
            guard let data = value.data(using: .utf8) else {
                print("🗝️ '\(key)' UTF-8 인코딩 실패")
                return
            }

            // 원자적 연산으로 race condition 방지
            if controller.read(key) != nil {
                controller.update(data, key: key)
            } else {
                controller.create(data, key: key)
            }
        }
    }

    public func delete(_ key: KeyChainKey) {
        keychainQueue.sync {
            controller.delete(key)
        }
    }

    public func deleteAll() {
        keychainQueue.sync {
            KeyChainKey.allCases.forEach { controller.delete($0) }
        }
    }
}
