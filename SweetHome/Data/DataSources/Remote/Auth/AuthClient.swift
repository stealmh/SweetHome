//
//  AuthClient.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation
import RxSwift

class AuthClient {
    private let network: NetworkServiceProtocol
    
    init(network: NetworkServiceProtocol = NetworkService.shared) {
        self.network = network
    }
    
    // MARK: - Generic Observable Methods
    func request<T: Decodable>(_ endpoint: AuthEndpoint) -> Observable<T> {
        print(#function)
        return Observable.create { observer in
            Task {
                do {
                    let response: T = try await self.network.request(endpoint)
                    await MainActor.run {
                        observer.onNext(response)
                        observer.onCompleted()
                    }
                } catch {
                    await MainActor.run {
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Generic Async/Await Methods
    func request<T: Decodable>(_ endpoint: AuthEndpoint) async throws -> T {
        print(#function)
        return try await network.request(endpoint)
    }
}
