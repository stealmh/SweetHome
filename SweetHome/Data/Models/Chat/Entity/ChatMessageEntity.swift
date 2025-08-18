//
//  ChatMessageEntity.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RealmSwift

class ChatMessageEntity: Object {
    @Persisted var chatId: String = ""
    @Persisted var roomId: String = ""
    @Persisted var content: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
    @Persisted var senderId: String = ""
    @Persisted var senderNickname: String = ""
    @Persisted var senderIntroduction: String?
    @Persisted var senderProfileImageURL: String?
    @Persisted var attachedFiles: List<String>
    @Persisted var isRead: Bool = false
    @Persisted var messageType: String = "text" // MessageType.rawValue
    
    override static func primaryKey() -> String? {
        return "chatId"
    }
}

// MARK: - Domain to Entity Extensions
extension LastChat {
    func toEntity() -> ChatMessageEntity {
        let entity = ChatMessageEntity()
        entity.chatId = chatId
        entity.roomId = roomId
        entity.content = content
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        entity.senderId = sender.userId
        entity.senderNickname = sender.nickname
        entity.senderIntroduction = sender.introduction
        entity.senderProfileImageURL = sender.profileImageURL
        entity.attachedFiles.append(objectsIn: attachedFiles)
        entity.messageType = "text" // 기본값
        return entity
    }
}

// MARK: - Entity to Domain Extensions
extension ChatMessageEntity {
    func toDomain() -> LastChat {
        return LastChat(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: ChatSender(
                userId: senderId,
                nickname: senderNickname,
                introduction: senderIntroduction,
                profileImageURL: senderProfileImageURL
            ),
            attachedFiles: Array(attachedFiles)
        )
    }
}