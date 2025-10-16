//
//  FileType.swift
//  SweetHome
//
//  Created by 김민호 on 10/16/25.
//

import Foundation

public enum FileType {
    case photo(Data)
    case voice(VoiceMessageData)

    var data: Data {
        switch self {
        case .photo(let data):
            return data
        case .voice(let voiceData):
            return voiceData.audioData
        }
    }

    var fileName: String {
        let userId = KeyChainManager.shared.read(.userID) ?? ""
        let timestamp = Int(Date().timeIntervalSince1970)

        switch self {
        case .photo:
            return "\(userId)_\(timestamp).jpg"
        case .voice(let voiceData):
            return voiceData.generatedFileName
        }
    }

    var mimeType: String {
        switch self {
        case .photo:
            return "image/jpeg"
        case .voice:
            return "audio/mp4"
        }
    }

    var messageContent: String {
        switch self {
        case .photo:
            return "사진"
        case .voice:
            return "음성메시지"
        }
    }
}
