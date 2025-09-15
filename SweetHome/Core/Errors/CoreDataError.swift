//
//  CoreDataError.swift
//  SweetHome
//
//  Created by 김민호 on 9/1/25.
//

import Foundation

enum CoreDataError {
    /// - 데이터 저장이 실패했을 때
    case saveFailed(String)
    /// - 데이터 조회가 실패했을 때
    case fetchFailed(String)
    /// - 데이터 삭제가 실패했을 때
    case deleteFailed(String)
    /// - 요청한 엔티티를 찾을 수 없을 때
    case entityNotFound(String)
    /// - CoreData 컨텍스트를 사용할 수 없을 때
    case contextUnavailable
    /// - 데이터베이스 마이그레이션이 실패했을 때
    case migrationFailed
}

extension CoreDataError {
    var message: String {
        switch self {
        case .saveFailed(let entity):
            return "\(entity) 저장에 실패했습니다."
        case .fetchFailed(let entity):
            return "\(entity) 조회에 실패했습니다."
        case .deleteFailed(let entity):
            return "\(entity) 삭제에 실패했습니다."
        case .entityNotFound(let entity):
            return "\(entity)을(를) 찾을 수 없습니다."
        case .contextUnavailable:
            return "데이터베이스 컨텍스트를 사용할 수 없습니다."
        case .migrationFailed:
            return "데이터베이스 마이그레이션에 실패했습니다."
        }
    }
    
    var displayType: ErrorDisplayType {
        switch self {
        case .saveFailed, .fetchFailed, .deleteFailed, .migrationFailed:
            return .toast
        case .entityNotFound:
            return .componentText
        case .contextUnavailable:
            return .none
        }
    }
}