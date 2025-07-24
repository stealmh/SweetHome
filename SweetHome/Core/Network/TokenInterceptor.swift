//
//  TokenInterceptor.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

import Foundation
import Alamofire

final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor()
    private let keyChainManager = KeyChainManager.shared
    private let logger = NetworkLogger.shared
    
    private init() {}
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        if let accessToken = keyChainManager.read(.accessToken) {
            adaptedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(adaptedRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else { 
            completion(.doNotRetryWithError(error))
            return
        }
        
        logger.logTokenRefresh()
        
        Task {
            do {
                // TODO: Refresh API 호출하고 값 넣기
                logger.logTokenRefreshSuccess()
                completion(.retry)
            } catch {
                logger.logTokenRefreshFailed(error)
                keyChainManager.deleteAll()
                logger.logTokenCleared()
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
