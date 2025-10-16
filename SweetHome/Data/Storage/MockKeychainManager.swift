//
//  MockKeychainManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import Foundation

final class MockKeychainManager: KeyChainManagerProtocol {
    private var storage: [KeyChainKey: String] = [:]
    private let mockQueue = DispatchQueue(label: "com.sweethome.mock-keychain", qos: .userInitiated)
    
    func contains(_ key: KeyChainKey) -> Bool {
        return mockQueue.sync {
            return storage[key] != nil
        }
    }
    
    func read(_ key: KeyChainKey) -> String? {
        return mockQueue.sync {
            return storage[key]
        }
    }
    
    func save(_ key: KeyChainKey, value: String) {
        mockQueue.sync {
            storage[key] = value
        }
    }
    
    func delete(_ key: KeyChainKey) {
        mockQueue.sync {
            storage.removeValue(forKey: key)
        }
    }
    
    func deleteAll() {
        mockQueue.sync {
            storage.removeAll()
        }
    }
}
