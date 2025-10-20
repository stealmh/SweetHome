//
//  CDParticipant+Extensions.swift
//  SweetHome
//
//  Created by 김민호 on 8/26/25.
//

import CoreData
import Foundation

// MARK: - Domain to Entity Extensions
extension Participant {
    func toEntity(context: NSManagedObjectContext) -> SweetHome.CDParticipant {
        let entity = SweetHome.CDParticipant(context: context)
        entity.userId = userId
        entity.nickname = nickname
        entity.introduction = introduction
        entity.profileImageURL = profileImageURL
        return entity
    }
}

// MARK: - Entity to Domain Extensions
extension SweetHome.CDParticipant {
    func toDomain() -> Participant {
        return Participant(
            userId: userId ?? "",
            nickname: nickname ?? "",
            introduction: introduction,
            profileImageURL: profileImageURL
        )
    }
}