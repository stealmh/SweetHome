//
//  ApiClientProtocol.swift
//  CoreNetwork
//
//  Created by Claude on 10/21/25.
//

import Foundation
import RxSwift

/// - API Client Protocol
/// - 네트워크 요청을 추상화하는 프로토콜
public protocol ApiClientProtocol {
    /// - RxSwift Observable을 반환하는 네트워크 요청
    func requestObservable<T: Decodable>(_ endpoint: TargetType) -> Observable<T>
}
