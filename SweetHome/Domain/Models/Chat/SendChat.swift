//
//  SendChat.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

struct SendChat: Encodable {
    let content: String
    let files: [String]?
}