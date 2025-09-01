//
//  CommonError.swift
//  SweetHome
//
//  Created by 김민호 on 8/1/25.
//

enum CommonError {
    /// - 키체인에서 키를 찾을 수 없을 때
    case keyNotFound
    /// - weak self 참조가 해제되었을 때
    case weakSelfFailure
}

extension CommonError {
    var message: String {
        switch self {
        case .keyNotFound:
            return "키를 찾을 수 없습니다."
        case .weakSelfFailure:
            return "참조 할 수 없습니다."
        }
    }

    var displayType: ErrorDisplayType {
        switch self {
        case .keyNotFound:
            return .none
        case .weakSelfFailure:
            return .none
        }
    }
    
    /// 기존 호환성을 위한 프로퍼티
    var shouldShowToast: Bool {
        return displayType == .toast
    }
}
