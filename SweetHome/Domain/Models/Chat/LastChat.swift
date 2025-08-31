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
        return content
    }
    let createdAt: Date
    let updatedAt: Date
    let sender: ChatSender
    let attachedFiles: [String]
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
