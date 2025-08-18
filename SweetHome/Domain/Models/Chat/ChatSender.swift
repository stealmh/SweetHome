//
//  ChatSender.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct ChatSender: Hashable {
    let userId: String
    let nickname: String
    let introduction: String?
    let profileImageURL: String?
}

extension SenderResponse {
    func toDomain() -> ChatSender {
        return ChatSender(
            userId: user_id,
            nickname: nick,
            introduction: introduction,
            profileImageURL: profileImage
        )
    }
}
