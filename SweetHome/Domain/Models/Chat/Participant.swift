//
//  Participant.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

public struct Participant: Hashable {
    public let userId: String
    public let nickname: String
    public let introduction: String?
    public let profileImageURL: String?

    public init(userId: String, nickname: String, introduction: String?, profileImageURL: String?) {
        self.userId = userId
        self.nickname = nickname
        self.introduction = introduction
        self.profileImageURL = profileImageURL
    }
}

// MARK: - Domain 변환 Extensions
extension ParticipantResponse {
    func toDomain() -> Participant {
        return Participant(
            userId: user_id,
            nickname: nick,
            introduction: introduction,
            profileImageURL: profileImage
        )
    }
}