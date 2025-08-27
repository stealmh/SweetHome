//
//  NotificationManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import UserNotifications

class NotificationManager: NSObject {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Request
    func requestNotificationPermission() async -> Bool {
        return await NotificationPermissionManager.shared.requestNotificationPermission()
    }
    
    // MARK: - Token Management
    func setAPNsToken(_ deviceToken: Data) {
        NotificationPermissionManager.shared.setAPNsToken(deviceToken)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // 앱이 foreground에 있을 때 푸시 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // 현재 채팅방에 있는 경우 -> 알림 미표시
        if let roomId = NotificationParser.shared.getRoomId(userInfo) {
            let isInTargetRoom = ChatSocketManager.shared.joinedRoomIds.contains(roomId)
            
            if isInTargetRoom {
                completionHandler([])
                return
            }
        }
        
        // FCM 메시지 처리 (데이터 업데이트)
        handleFCMMessage(userInfo)
        
        // 다른 채팅방이거나 채팅방이 아닌 경우 알림 표시
        print("   - 알림 표시함")
        completionHandler([.banner, .badge, .sound, .list])
    }
    
    // 사용자가 푸시 알림을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleFCMMessage(userInfo)
        NotificationNavigator.shared.handleNotificationTap(userInfo)
        completionHandler()
    }
    
    // FCM 메시지 공통 처리
    private func handleFCMMessage(_ userInfo: [AnyHashable: Any]) {
        print("FCM Message received: \(userInfo)")
        
        // FCM 데이터 확인
        if let messageId = NotificationParser.shared.getFCMMessageId(userInfo) {
            print("FCM Message ID: \(messageId)")
        }
        
        // 채팅 메시지인 경우 처리
        if let chatData = NotificationParser.shared.parseChatNotification(userInfo) {
            ChatNotificationHandler.shared.handleChatNotification(chatData)
        }
    }
    
    // 채팅방의 메세지를 읽음 처리함(채팅방 진입 시 호출)
    func markRoomAsRead(_ roomId: String) {
        ChatNotificationHandler.shared.markRoomAsRead(roomId)
    }
    
    // 백그라운드에서 채팅 알림 처리
    func handleBackgroundChatNotification(_ userInfo: [AnyHashable: Any]) {
        guard let chatData = NotificationParser.shared.parseChatNotification(userInfo) else { return }
        
        print("🌙 [백그라운드] 채팅 알림 처리: \(chatData.roomId)")
        ChatNotificationHandler.shared.handleChatNotification(chatData)
    }
    
    // 앱이 포그라운드로 돌아올 때 안읽음 카운트 동기화
    func syncUnreadCountsOnForeground() {
        ChatNotificationHandler.shared.syncUnreadCountsOnForeground()
    }
}
