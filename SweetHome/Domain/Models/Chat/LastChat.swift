//
//  LastChat.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct LastChat: Hashable {
    let chatId: String
    let roomId: String
    let content: String

    var displayLabel: String {
        if content == "사진" && !attachedFiles.isEmpty {
            return "사진"
        }
        if content == "음성메시지" && !attachedFiles.isEmpty {
            return "음성메시지"
        }
        return content
    }
    let createdAt: Date
    let updatedAt: Date
    let sender: ChatSender
    let attachedFiles: [String]

    /// - 메시지 타입 구분
    var chatMessageType: ChatMessageType {
        if content == "사진" && !attachedFiles.isEmpty {
            return .image
        }
        if content == "음성메시지" && !attachedFiles.isEmpty {
            return .voice
        }
        return .text
    }
}

/// - 채팅 메시지 타입 열거형
enum ChatMessageType {
    case text
    case image
    case voice
}

extension LastChatResponse {
    func toDomain() -> LastChat {
        let formatter = ISO8601DateFormatter()
        
        return LastChat(
            chatId: chat_id,
            roomId: room_id,
            content: content,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date(),
            sender: sender.toDomain(),
            attachedFiles: files
        )
    }
}
