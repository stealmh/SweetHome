//
//  NetworkError.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import AuthenticationServices

enum NetworkError {
    /// - 네트워크 연결이 실패했을 때
    case connectionFailed(String)
    /// - 서버에서 에러를 반환했을 때
    case serverError(statusCode: Int, message: String)
    /// - JSON 디코딩이 실패했을 때
    case decodingError
    /// - 액세스 토큰이 만료되었을 때
    case tokenExpired
    /// - 리프레시 토큰이 만료되었을 때
    case refreshTokenExpired
    /// - 알 수 없는 네트워크 에러가 발생했을 때
    case unknown(statusCode: Int?, message: String)
    /// - Apple 로그인에서 에러가 발생했을 때
    case apple(ASAuthorizationError.Code)
}

extension NetworkError {
    var message: String {
        switch self {
        case .connectionFailed(let message):
            return message
        case .serverError(_, let message):
            return message
        case .decodingError:
            return "데이터 인코딩 중 오류가 발생했습니다."
        case .tokenExpired:
            return "리프레시 토큰이 없습니다."
        case .refreshTokenExpired:
            return "세션이 만료되었습니다. 다시 로그인해주세요."
        case .unknown(_, let message):
            return message
        case .apple(let error):
            return appleErrorMessage(error)
        }
    }
    
    var displayType: ErrorDisplayType {
        switch self {
        case .connectionFailed(_):
            return .toast
        case .serverError(let statusCode, _):
            return statusCodeDisplayType(statusCode)
        case .decodingError:
            return .none // 개발자용 에러
        case .tokenExpired:
            return .none // 내부적으로 처리
        case .refreshTokenExpired:
            return .toast // 사용자에게 재로그인 알림
        case .unknown(let statusCode, _):
            if let code = statusCode {
                return statusCodeDisplayType(code)
            }
            return .toast
        case .apple(let error):
            return appleErrorDisplayType(error)
        }
    }
    
    private func statusCodeDisplayType(_ statusCode: Int) -> ErrorDisplayType {
        switch statusCode {
        case 418:
            return .toast
        case 419:
            return .none
        //TODO: 구분하기
        case 400...499:
            return .toast
        case 500...599:
            return .toast
        default:
            return .toast
        }
    }
    
    /// Apple 로그인 에러 메시지 처리
    private func appleErrorMessage(_ error: ASAuthorizationError.Code) -> String {
        switch error {
        case .canceled:
            return "Apple 로그인이 취소되었습니다."
        case .failed:
            return "Apple 로그인에 실패했습니다."
        case .invalidResponse:
            return "Apple 로그인 응답이 유효하지 않습니다."
        case .notHandled:
            return "Apple 로그인을 처리할 수 없습니다."
        case .unknown:
            return "알 수 없는 Apple 로그인 오류가 발생했습니다."
        case .notInteractive:
            return "대화형이 아닌 Apple 로그인 요청입니다."
        default:
            return "Apple 로그인 중 오류가 발생했습니다."
        }
    }
    
    /// Apple 로그인 에러 표시 타입 처리
    private func appleErrorDisplayType(_ error: ASAuthorizationError.Code) -> ErrorDisplayType {
        switch error {
        case .canceled:
            return .none
        case .failed, .invalidResponse, .notHandled, .unknown, .notInteractive:
            return .toast
        default:
            return .toast
        }
    }
}
