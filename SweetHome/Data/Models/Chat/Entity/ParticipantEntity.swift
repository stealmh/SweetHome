//
//  ParticipantEntity.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RealmSwift

class ParticipantEntity: Object {
    @Persisted(primaryKey: true) var userId: String = ""
    @Persisted var nickname: String = ""
    @Persisted var introduction: String?
    @Persisted var profileImageURL: String?
}

// MARK: - Domain to Entity Extensions
extension Participant {
    func toEntity() -> ParticipantEntity {
        let entity = ParticipantEntity()
        entity.userId = userId
        entity.nickname = nickname
        entity.introduction = introduction
        entity.profileImageURL = profileImageURL
        return entity
    }
}

// MARK: - Entity to Domain Extensions
extension ParticipantEntity {
    func toDomain() -> Participant {
        return Participant(
            userId: userId,
            nickname: nickname,
            introduction: introduction,
            profileImageURL: profileImageURL
        )
    }
}