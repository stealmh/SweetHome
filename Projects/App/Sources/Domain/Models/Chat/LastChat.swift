//
//  LastChat.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

public struct LastChat: Hashable {
    public let chatId: String
    public let roomId: String
    public let content: String

    public var displayLabel: String {
        if content == "사진" && !attachedFiles.isEmpty {
            return "사진"
        }
        if content == "음성메시지" && !attachedFiles.isEmpty {
            return "음성메시지"
        }
        return content
    }
    public let createdAt: Date
    public let updatedAt: Date
    public let sender: ChatSender
    public let attachedFiles: [String]

    public init(chatId: String, roomId: String, content: String, createdAt: Date, updatedAt: Date, sender: ChatSender, attachedFiles: [String]) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.attachedFiles = attachedFiles
    }

    /// - 메시지 타입 구분
    public var chatMessageType: ChatMessageType {
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
public enum ChatMessageType {
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
