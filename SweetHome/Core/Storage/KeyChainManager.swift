//
//  KeyChainManager.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

// MARK: - KeychainManagerProtocol
protocol KeyChainManagerProtocol: Sendable {
    func read(_ key: KeyChainKey) -> String?
    func save(_ key: KeyChainKey, value: String)
    func delete(_ key: KeyChainKey)
    func deleteAll()
    func contains(_ key: KeyChainKey) -> Bool
}

// MARK: - Thread-Safe KeychainManager Implementation
final class KeyChainManager: KeyChainManagerProtocol {
    static let shared = KeyChainManager()
    
    private let controller: KeyChainControllerProtocol
    private let keychainQueue: DispatchQueue
    
    init(controller: KeyChainControllerProtocol = KeyChainController()) {
        self.controller = controller
        self.keychainQueue = DispatchQueue(
            label: "com.sweethome.keychain", 
            qos: .userInitiated
        )
    }
    
    // Convenience initializer for shared instance
    convenience init() {
        self.init(controller: KeyChainController())
    }
    
    func contains(_ key: KeyChainKey) -> Bool {
        return keychainQueue.sync {
            print("🗝️ '\(key)' 값이 포함되어 있는지 확인중 입니다.")
            return controller.read(key) != nil
        }
    }
    
    func read(_ key: KeyChainKey) -> String? {
        return keychainQueue.sync {
            guard let data = controller.read(key) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }
    
    func save(_ key: KeyChainKey, value: String) {
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
    
    func delete(_ key: KeyChainKey) {
        keychainQueue.sync {
            controller.delete(key)
        }
    }
    
    func deleteAll() {
        keychainQueue.sync {
            KeyChainKey.allCases.forEach { controller.delete($0) }
        }
    }
}

