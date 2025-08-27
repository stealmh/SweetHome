//
//  ChatRoomResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

/// - 채팅방 생성/조회
struct ChatRoomResponse: Decodable {
    let room_id: String
    let createdAt: String
    let updatedAt: String
    let participants: [ParticipantResponse]
    let lastChat: LastChatResponse?
}
