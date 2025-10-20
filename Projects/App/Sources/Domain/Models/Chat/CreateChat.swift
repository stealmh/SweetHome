//
//  CreateChat.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

public struct CreateChat: Encodable {
    public let opponent_id: String

    public init(opponent_id: String) {
        self.opponent_id = opponent_id
    }
}