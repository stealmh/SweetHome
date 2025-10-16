//
//  ChatRoom.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

public struct ChatRoom: Hashable {
    public let roomId: String
    public let createdAt: Date
    public let updatedAt: Date
    public let participants: [Participant]
    public let lastChat: LastChat?
    public let lastPushMessage: String?
    public let lastPushMessageDate: Date?
    public let unreadCount: Int

    public init(roomId: String, createdAt: Date, updatedAt: Date, participants: [Participant], lastChat: LastChat?, lastPushMessage: String?, lastPushMessageDate: Date?, unreadCount: Int) {
        self.roomId = roomId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.participants = participants
        self.lastChat = lastChat
        self.lastPushMessage = lastPushMessage
        self.lastPushMessageDate = lastPushMessageDate
        self.unreadCount = unreadCount
    }
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
            lastPushMessage: nil,
            lastPushMessageDate: nil,
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
            lastPushMessage: nil,
            lastPushMessageDate: nil,
            unreadCount: 0
        )
    }
}
