//
//  SenderResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/19/25.
//

/// - 보낸사람
struct SenderResponse: Codable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}
