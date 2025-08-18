//
//  ChatRoomResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct ChatRoomResponse: Codable {
    let data: [ChatRoomData]
}

struct ChatRoomData: Codable {
    let room_id: String
    let createdAt: String
    let updatedAt: String
    let participants: [ParticipantResponse]
    let lastChat: LastChatResponse
}

struct ParticipantResponse: Codable {
    let user_id: String
    let nick: String
    let introduction: String
    let profileImage: String
}

struct LastChatResponse: Codable {
    let chat_id: String
    let room_id: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: SenderResponse
    let files: [String]
}

struct SenderResponse: Codable {
    let user_id: String
    let nick: String
    let introduction: String
    let profileImage: String
}
