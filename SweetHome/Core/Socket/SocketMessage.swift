//
//  SocketMessage.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct SocketMessage: Codable {
    let id: String
    let roomId: String
    let senderId: String
    let senderName: String
    let senderProfileImage: String?
    let content: String
    let timestamp: Date
    let messageType: MessageType
    let files: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case roomId = "room_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderProfileImage = "sender_profile_image"
        case content
        case timestamp
        case messageType = "message_type"
        case files
    }
}

enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
}

struct SocketRoomJoinRequest: Codable {
    let roomId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case userId = "user_id"
    }
}

struct SocketMessageRequest: Codable {
    let roomId: String
    let content: String
    let messageType: MessageType
    let files: [String]?
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case content
        case messageType = "message_type"
        case files
    }
}

struct SocketTypingRequest: Codable {
    let roomId: String
    let userId: String
    let isTyping: Bool
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case userId = "user_id"
        case isTyping = "is_typing"
    }
}

struct SocketUser: Codable {
    let userId: String
    let nickname: String
    let profileImage: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname = "nick"
        case profileImage = "profile_image"
    }
}

struct SocketTypingStatus: Codable {
    let roomId: String
    let user: SocketUser
    let isTyping: Bool
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case user
        case isTyping = "is_typing"
    }
}