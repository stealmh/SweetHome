//
//  ParticipantResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/19/25.
//

/// - 채팅 참가자
struct ParticipantResponse: Decodable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}
