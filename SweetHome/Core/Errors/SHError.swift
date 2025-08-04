//
//  SHError.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

enum ErrorDisplayType {
    case toast
    case componentText
    case none
}

enum SHError: Error {
    case commonError(CommonError)
    /// - 클라이언트에서 발생한 에러
    case clientError(ClientError)
    /// - 네트워크/서버를 통해 발생한 에러
    case networkError(NetworkError)
    
    var message: String {
        switch self {
        case let .commonError(error):
            return error.message
            
        case let .clientError(.textfield(error)):
            return error.message
            
        case let .networkError(error):
            return error.message
        }
    }
    
    /// 에러를 어떤 방식으로 표시할지 결정
    var displayType: ErrorDisplayType {
        switch self {
        case .commonError(let error):
            return error.displayType
        case .clientError(let error):
            return error.displayType
        case .networkError(let error):
            return error.displayType
        }
    }
    
    /// 기존 호환성을 위한 프로퍼티
    var shouldShowToast: Bool {
        return displayType == .toast
    }
}

extension SHError {
    /// - Error to SHError
    static func from(_ error: Error) -> SHError {
        if let shError = error as? SHError { return shError }
        return .networkError(.unknown(statusCode: nil, message: "잠시후 다시 시도해주세요."))
    }
}

