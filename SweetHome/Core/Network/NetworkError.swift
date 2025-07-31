//
//  NetworkError.swift
//  SweetHome
//
//  Created by 김민호 on 7/24/25.
//

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case serverError(Int)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .noData:
            return "데이터가 없습니다."
        case .decodingError:
            return "데이터 파싱 오류입니다."
        case .encodingError:
            return "데이터 인코딩 오류입니다."
        case .serverError(let code):
            return "서버 오류: \(code)"
        case .unknown:
            return "알 수 없는 오류입니다."
        }
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
