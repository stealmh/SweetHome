//
//  ApiClient.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation
import RxSwift

// MARK: - ApiClient Class
class ApiClient {
    private let network: NetworkServiceProtocol
    
    init(network: NetworkServiceProtocol = NetworkService.shared) {
        self.network = network
    }
    
    // MARK: - Observable 방식 (RxSwift 기반)
    /// RxSwift Observable을 반환하는 네트워크 요청
    /// - Parameter endpoint: 요청할 엔드포인트
    /// - Returns: Observable<T> 타입의 응답
    /// - Note: TokenInterceptor가 토큰 갱신을 자동으로 처리하므로 별도 재시도 로직 불필요
    func requestObservable<T: Decodable>(_ endpoint: TargetType) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SHError.networkError(.unknown(statusCode: nil, message: "ApiClient가 해제되었습니다.")))
                return Disposables.create()
            }
            
            let task = Task {
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
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // MARK: - Async/Await 방식 (일반 제네릭 타입)
    /// async/await를 사용한 네트워크 요청
    /// - Parameter endpoint: 요청할 엔드포인트
    /// - Returns: 제네릭 타입 T의 응답
    /// - Throws: 네트워크 에러
    func request<T: Decodable>(_ endpoint: TargetType) async throws -> T {
        return try await network.request(endpoint)
    }
}

// MARK: - Shared Instance
extension ApiClient {
    static let shared = ApiClient()
}
