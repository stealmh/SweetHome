//
//  ChatRoom.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct ChatRoom: Hashable {
    let roomId: String
    let createdAt: Date
    let updatedAt: Date
    let participants: [Participant]
    let lastChat: LastChat?
    let unreadCount: Int
}

extension ChatRoomResponse {
    func toDomain() -> ChatRoom {
        let formatter = ISO8601DateFormatter()
        
        return ChatRoom(
            roomId: room_id,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date(),
            participants: participants.map { $0.toDomain() },
            lastChat: lastChat?.toDomain() ?? createDefaultLastChat(),
            unreadCount: 0
        )
    }
    
    private func createDefaultLastChat() -> LastChat {
        return LastChat(
            chatId: UUID().uuidString,
            roomId: room_id,
            content: "새로운 채팅을 시작하세요",
            createdAt: Date(),
            updatedAt: Date(),
            sender: ChatSender(
                userId: "",
                nickname: "",
                introduction: "",
                profileImageURL: ""
            ),
            attachedFiles: []
        )
    }
}

extension ChatRoomListDataResponse {
    func toDomain() -> ChatRoom {
        let formatter = ISO8601DateFormatter()
        
        return ChatRoom(
            roomId: room_id,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date(),
            participants: participants.map { $0.toDomain() },
            lastChat: lastChat?.toDomain(),
            unreadCount: 0
        )
    }
}
