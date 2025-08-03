//
//  CommonError.swift
//  SweetHome
//
//  Created by 김민호 on 8/1/25.
//

enum CommonError {
    case keyNotFound
    case weakSelfFailure
    
    var message: String {
        switch self {
        case .keyNotFound:
            return "키를 찾을 수 없습니다."
        case .weakSelfFailure:
            return "참조 할 수 없습니다."
        }
    }
}
