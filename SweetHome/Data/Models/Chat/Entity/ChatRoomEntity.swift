//
//  ChatRoomEntity.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RealmSwift

class ChatRoomEntity: Object {
    @Persisted var roomId: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
    @Persisted var participants: List<ParticipantEntity>
    @Persisted var lastChatId: String?
    @Persisted var unreadCount: Int = 0
    
    override static func primaryKey() -> String? {
        return "roomId"
    }
}

// MARK: - Domain to Entity Extensions
extension ChatRoom {
    func toEntity() -> ChatRoomEntity {
        let entity = ChatRoomEntity()
        entity.roomId = roomId
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        entity.lastChatId = lastChat?.chatId
        entity.participants.append(objectsIn: participants.map { $0.toEntity() })
        return entity
    }
}

// MARK: - Entity to Domain Extensions
extension ChatRoomEntity {
    func toDomain(with lastChat: LastChat) -> ChatRoom {
        return ChatRoom(
            roomId: roomId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            participants: participants.map { $0.toDomain() },
            lastChat: lastChat
        )
    }
}