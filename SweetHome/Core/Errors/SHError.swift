//
//  SHError.swift
//  SweetHome
//
//  Created by 김민호 on 7/31/25.
//

import Foundation

// MARK: - SweetHome Error Hierarchy
enum SHError: Error, LocalizedError {
    case auth(AuthError)
    case validation(ValidationError)
    case network(NetworkError)
    case login(LoginError)
    case register(RegisterError)
    
    var errorDescription: String? {
        switch self {
        case .auth(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        case .network(let error):
            return error.errorDescription
        case .login(let error):
            return error.errorDescription
        case .register(let error):
            return error.errorDescription
        }
    }
}

// MARK: - SHError Convenience Extensions
extension SHError {
    // Auth shortcuts
    static var invalidCredentials: SHError { .auth(.invalidCredentials) }
    static var userCanceled: SHError { .auth(.userCanceled) }
    static var authenticationFailed: SHError { .auth(.authenticationFailed) }
    static func socialLoginFailed(_ provider: String) -> SHError { .auth(.socialLoginFailed(provider)) }
    
    // Validation shortcuts
    static var invalidEmail: SHError { .validation(.invalidEmail) }
    static var weakPassword: SHError { .validation(.weakPassword) }
    static var emptyNickname: SHError { .validation(.emptyNickname) }
    static func emptyField(_ field: String) -> SHError { .validation(.emptyField(field)) }
    
    // Network shortcuts
    static var connectionFailed: SHError { .network(.connectionFailed) }
    static var timeout: SHError { .network(.timeout) }
    static func serverError(_ code: Int) -> SHError { .network(.serverError(code)) }
    static var decodingError: SHError { .network(.decodingError) }
    static var encodingError: SHError { .network(.encodingError) }
    static var invalidURL: SHError { .network(.invalidURL) }
    static var noData: SHError { .network(.noData) }
    static func networkError(_ error: Error) -> SHError { .network(.unknown(error)) }
}

// MARK: - Authentication Errors
extension SHError {
    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case userCanceled
        case authenticationFailed
        case invalidResponse
        case notHandled
        case unknown
        case notImplemented
        case socialLoginFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "이메일 또는 비밀번호가 올바르지 않습니다."
            case .userCanceled:
                return "사용자가 로그인을 취소했습니다."
            case .authenticationFailed:
                return "인증에 실패했습니다."
            case .invalidResponse:
                return "잘못된 응답입니다."
            case .notHandled:
                return "처리되지 않은 오류입니다."
            case .unknown:
                return "알 수 없는 오류가 발생했습니다."
            case .notImplemented:
                return "아직 구현되지 않은 기능입니다."
            case .socialLoginFailed(let provider):
                return "\(provider) 로그인에 실패했습니다."
            }
        }
    }
}

// MARK: - Validation Errors
extension SHError {
    enum ValidationError: Error, LocalizedError {
        case invalidEmail
        case weakPassword
        case emptyNickname
        case emptyField(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "유효하지 않은 이메일 형식입니다."
            case .weakPassword:
                return "비밀번호는 최소 8자 이상이며, 영문자, 숫자, 특수문자를 포함해야 합니다."
            case .emptyNickname:
                return "닉네임을 입력해주세요."
            case .emptyField(let fieldName):
                return "\(fieldName)을(를) 입력해주세요."
            }
        }
    }
}

// MARK: - Network Errors
extension SHError {
    enum NetworkError: Error, LocalizedError {
        case connectionFailed
        case timeout
        case serverError(Int)
        case decodingError
        case encodingError
        case invalidURL
        case noData
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .connectionFailed:
                return "네트워크 연결에 실패했습니다."
            case .timeout:
                return "요청 시간이 초과되었습니다."
            case .serverError(let statusCode):
                return "서버 오류가 발생했습니다. (코드: \(statusCode))"
            case .decodingError:
                return "데이터 변환 중 오류가 발생했습니다."
            case .encodingError:
                return "데이터 인코딩 중 오류가 발생했습니다."
            case .invalidURL:
                return "유효하지 않은 URL입니다."
            case .noData:
                return "데이터가 없습니다."
            case .unknown(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            }
        }
        
        var localizedDescription: String {
            return errorDescription ?? "알 수 없는 네트워크 오류"
        }
        
        var statusCode: Int? {
            switch self {
            case .serverError(let code):
                return code
            default:
                return nil
            }
        }
    }
}

// MARK: - Login Errors
extension SHError {
    enum LoginError: Error, LocalizedError {
        case invalidCredentials
        case socialLoginFailed(String)
        case userCanceled
        case authenticationFailed
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "이메일 또는 비밀번호가 올바르지 않습니다."
            case .socialLoginFailed(let provider):
                return "\(provider) 로그인에 실패했습니다."
            case .userCanceled:
                return "사용자가 로그인을 취소했습니다."
            case .authenticationFailed:
                return "인증에 실패했습니다."
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Register Errors
extension SHError {
    enum RegisterError: Error, LocalizedError {
        case invalidEmail
        case weakPassword
        case emptyNickname
        case userAlreadyExists
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "유효하지 않은 이메일 형식입니다."
            case .weakPassword:
                return "비밀번호는 최소 8자 이상이며, 영문자, 숫자, 특수문자를 포함해야 합니다."
            case .emptyNickname:
                return "닉네임을 입력해주세요."
            case .userAlreadyExists:
                return "이미 존재하는 사용자입니다."
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            }
        }
    }
}