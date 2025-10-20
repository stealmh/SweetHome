//
//  ChatRoomListResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/19/25.
//

/// - 채팅방 목록 조회
struct ChatRoomListResponse: Decodable {
    let data: [ChatRoomListDataResponse]
}

struct ChatRoomListDataResponse: Decodable {
    let room_id: String
    let createdAt: String
    let updatedAt: String
    let participants: [ParticipantResponse]
    let lastChat: LastChatResponse?
}
