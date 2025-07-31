//
//  SHError.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

enum SHError: Error {
    case commonError(CommonError)
    /// - 클라이언트에서 발생한 에러
    case clientError(ClientError)
    /// - 네트워크/서버를 통해 발생한 에러
    case networkError(String)
    
    var message: String {
        switch self {
        case let .commonError(error):
            return error.message
            
        case let .clientError(.textfield(error)):
            return error.message
            
        case let .networkError(message):
            return message
        }
    }
}

extension SHError {
    /// - Error to SHError
    static func from(_ error: Error) -> SHError {
        if let shError = error as? SHError { return shError }
        return .networkError("잠시후 다시 시도헤주세요.")
    }
}

