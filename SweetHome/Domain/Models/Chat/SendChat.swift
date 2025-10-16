//
//  SendChat.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation

public struct SendChat: Encodable {
    public let content: String
    public let files: [String]?

    public init(content: String, files: [String]?) {
        self.content = content
        self.files = files
    }
}