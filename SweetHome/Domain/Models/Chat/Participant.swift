//
//  Participant.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct Participant: Hashable {
    let userId: String
    let nickname: String
    let introduction: String?
    let profileImageURL: String?
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