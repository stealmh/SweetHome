//
//  CDChatMessage+Extensions.swift
//  SweetHome
//
//  Created by 김민호 on 8/26/25.
//

import CoreData
import Foundation

// MARK: - Domain to Entity Extensions
extension LastChat {
    func toEntity(context: NSManagedObjectContext) -> SweetHome.CDChatMessage {
        let entity = SweetHome.CDChatMessage(context: context)
        entity.chatId = chatId
        entity.roomId = roomId
        entity.content = content
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        entity.senderId = sender.userId
        entity.senderNickname = sender.nickname
        entity.senderIntroduction = sender.introduction
        entity.senderProfileImageURL = sender.profileImageURL
        entity.attachedFiles = attachedFiles
        entity.messageType = "text" // 기본값
        entity.isRead = false // 기본값
        return entity
    }
}

// MARK: - Entity to Domain Extensions  
extension SweetHome.CDChatMessage {
    func toDomain() -> LastChat {
        return LastChat(
            chatId: chatId ?? "",
            roomId: roomId ?? "",
            content: content ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            sender: ChatSender(
                userId: senderId ?? "",
                nickname: senderNickname ?? "",
                introduction: senderIntroduction,
                profileImageURL: senderProfileImageURL
            ),
            attachedFiles: attachedFiles ?? []
        )
    }
}