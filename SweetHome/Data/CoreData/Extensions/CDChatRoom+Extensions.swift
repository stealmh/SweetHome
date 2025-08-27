//
//  CDChatRoom+Extensions.swift
//  SweetHome
//
//  Created by 김민호 on 8/26/25.
//

import CoreData
import Foundation

// MARK: - Domain to Entity Extensions
extension ChatRoom {
    func toEntity(context: NSManagedObjectContext) -> SweetHome.CDChatRoom {
        let entity = SweetHome.CDChatRoom(context: context)
        entity.roomId = roomId
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        entity.lastChatId = lastChat?.chatId
        entity.lastPushMessage = lastPushMessage
        entity.lastPushMessageDate = lastPushMessageDate
        entity.unreadCount = Int32(unreadCount)
        
        // 참가자들 설정
        let participantEntities = participants.map { $0.toEntity(context: context) }
        entity.participants = NSSet(array: participantEntities)
        
        return entity
    }
}

// MARK: - Entity to Domain Extensions
extension SweetHome.CDChatRoom {
    func toDomain(with lastChat: LastChat?) -> ChatRoom {
        let participantsArray = (participants?.allObjects as? [SweetHome.CDParticipant]) ?? []
        return ChatRoom(
            roomId: roomId ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            participants: participantsArray.map { $0.toDomain() },
            lastChat: lastChat,
            lastPushMessage: lastPushMessage,
            lastPushMessageDate: lastPushMessageDate,
            unreadCount: Int(unreadCount)
        )
    }
}