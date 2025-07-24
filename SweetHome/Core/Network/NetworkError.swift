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
        case .serverError(let code):
            return "서버 오류: \(code)"
        case .unknown:
            return "알 수 없는 오류입니다."
        }
    }
}
