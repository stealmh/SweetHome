//
//  ClientError.swift
//  SweetHome
//
//  Created by 김민호 on 8/1/25.
//

public enum ClientError {
    case textfield(TextFieldCase)
}

public extension ClientError {
    var displayType: ErrorDisplayType {
        switch self {
        case .textfield(let error):
            return error.displayType
        }
    }
    
    /// 기존 호환성을 위한 프로퍼티
    var shouldShowToast: Bool {
        return displayType == .toast
    }
}
