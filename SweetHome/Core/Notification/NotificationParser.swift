//
//  NotificationParser.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import Foundation

final class NotificationParser {
    static let shared = NotificationParser()
    
    private init() {}
    
    func parseChatNotification(_ userInfo: [AnyHashable: Any]) -> ChatNotificationData? {
        print(#function)
        guard let roomId = userInfo["room_id"] as? String,
              let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let message = alert["body"] as? String else {
            return nil
        }
        
        return ChatNotificationData(
            roomId: roomId,
            message: message
        )
    }
    
    func isChatNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        return userInfo["room_id"] != nil
    }
    
    func getFCMMessageId(_ userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["gcm.message_id"] as? String
    }
    
    func getRoomId(_ userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["room_id"] as? String
    }
}