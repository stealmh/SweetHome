//
//  LastChatResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/19/25.
//

/// - 마지막 채팅내역
struct LastChatResponse: Codable {
    let chat_id: String
    let room_id: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: SenderResponse
    let files: [String]
}
