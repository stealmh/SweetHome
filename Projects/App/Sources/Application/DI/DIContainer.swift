//
//  DIContainer.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func resolve<T>(_ type: T.Type) -> T
}

class DIContainer: DIContainerProtocol {
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    private var instances: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        instances[key] = instance
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let instance = instances[key] as? T {
            return instance
        }
        
        if let factory = factories[key] {
            let instance = factory() as! T
            return instance
        }
        
        fatalError("No registration found for type \(type)")
    }
}