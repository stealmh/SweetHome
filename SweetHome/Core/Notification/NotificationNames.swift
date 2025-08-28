//
//  NotificationNames.swift
//  SweetHome
//
//  Created by 김민호 on 8/19/25.
//

import Foundation

extension Notification.Name {
    enum Chat {
        static let newMessageReceived = Notification.Name("NewChatMessageReceived")
        static let syncUnreadCounts = Notification.Name("SyncUnreadCountsFromRealm")
        static let navigateToChat = Notification.Name("NavigateToChat")
    }
    static let refreshTokenExpired = Notification.Name("refreshTokenExpired")
    static let mainTabBarReady = Notification.Name("MainTabBarReady")
}
