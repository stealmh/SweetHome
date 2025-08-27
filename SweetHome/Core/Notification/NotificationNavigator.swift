//
//  NotificationNavigator.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import Foundation

final class NotificationNavigator {
    static let shared = NotificationNavigator()
    
    private init() {}
    
    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        if let roomId = NotificationParser.shared.getRoomId(userInfo) {
            navigateToChat(roomId: roomId)
        }
    }
    
    private func navigateToChat(roomId: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .Chat.navigateToChat,
                object: nil,
                userInfo: ["roomId": roomId]
            )
        }
    }
}