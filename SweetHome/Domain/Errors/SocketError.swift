//
//  SocketError.swift
//  SweetHome
//
//  Created by 김민호 on 9/1/25.
//

import Foundation

enum SocketError {
    /// - 소켓 서버 연결이 실패했을 때
    case connectionFailed
    /// - 소켓 인증이 실패했을 때
    case authenticationFailed
    /// - 수신된 메시지 파싱이 실패했을 때
    case messageDecodingFailed
    /// - 채팅방 입장이 실패했을 때
    case roomJoinFailed(String)
    /// - 소켓 연결이 예기치 않게 끊어졌을 때
    case disconnectedUnexpectedly
    /// - 채팅 서버를 사용할 수 없을 때
    case serverUnavailable
}

extension SocketError {
    var message: String {
        switch self {
        case .connectionFailed:
            return "채팅 서버 연결에 실패했습니다."
        case .authenticationFailed:
            return "채팅 인증에 실패했습니다. 다시 로그인해주세요."
        case .messageDecodingFailed:
            return "메시지를 불러오는 중 오류가 발생했습니다."
        case .roomJoinFailed(let roomId):
            return "채팅방(\(roomId)) 입장에 실패했습니다."
        case .disconnectedUnexpectedly:
            return "채팅 연결이 끊어졌습니다. 다시 연결을 시도합니다."
        case .serverUnavailable:
            return "채팅 서버를 사용할 수 없습니다. 잠시 후 다시 시도해주세요."
        }
    }
    
    var displayType: ErrorDisplayType {
        switch self {
        case .connectionFailed, .authenticationFailed, .roomJoinFailed, .serverUnavailable:
            return .toast
        case .messageDecodingFailed:
            return .none
        case .disconnectedUnexpectedly:
            return .none // 자동 재연결 시도
        }
    }
}