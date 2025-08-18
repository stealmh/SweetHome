//
//  ChatModels.swift
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
    let lastChat: LastChat
}

struct Participant: Hashable {
    let userId: String
    let nickname: String
    let introduction: String
    let profileImageURL: String
}

struct LastChat: Hashable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let sender: ChatSender
    let attachedFiles: [String]
}

struct ChatSender: Hashable {
    let userId: String
    let nickname: String
    let introduction: String
    let profileImageURL: String
}
