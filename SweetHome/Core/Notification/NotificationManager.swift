//
//  NotificationManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import UserNotifications
import FirebaseMessaging

class NotificationManager: NSObject {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Permission Request
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            guard granted else { return false }
            
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            return true
        } catch {
            print("알림 권한 설정 중 오류: \(error)")
            return false
        }
    }
    
    // MARK: - Token Management
    func setAPNsToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        storeDeviceTokenIfNeeded(deviceToken)
    }
    
    private func storeDeviceTokenIfNeeded(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        KeyChainManager.shared.save(.deviceToken, value: tokenString)
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
        handleFCMMessage(userInfo)
        
        // foreground에서도 알림 표시
        completionHandler([.alert, .badge, .sound])
    }
    
    // 사용자가 푸시 알림을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleFCMMessage(userInfo)
        handleNotificationTap(userInfo)
        completionHandler()
    }
    
    // FCM 메시지 공통 처리
    private func handleFCMMessage(_ userInfo: [AnyHashable: Any]) {
        print("FCM Message received: \(userInfo)")
        
        // FCM 데이터 확인
        if let messageData = userInfo["gcm.message_id"] {
            print("FCM Message ID: \(messageData)")
        }
        
        // 채팅 메시지인 경우 처리
        if let chatData = parseChatNotification(userInfo) {
            handleChatNotification(chatData)
        }
    }
    
    // 알림 탭 처리
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // 채팅 메시지 알림인 경우 해당 채팅방으로 이동
        if let roomId = userInfo["room_id"] as? String {
            navigateToChat(roomId: roomId)
        }
    }
    
    // 채팅 알림 데이터 파싱
    private func parseChatNotification(_ userInfo: [AnyHashable: Any]) -> ChatNotificationData? {
        guard let roomId = userInfo["room_id"] as? String,
              let senderId = userInfo["sender_id"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let messageContent = userInfo["message"] as? String else {
            return nil
        }
        
        return ChatNotificationData(
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            message: messageContent
        )
    }
    
    // 채팅 알림 처리
    private func handleChatNotification(_ data: ChatNotificationData) {
        // 현재 채팅방에 있지 않은 경우에만 처리
        let socketRepository = ChatSocketRepository()
        
        // 새 메시지로 인한 읽지 않은 개수 업데이트
        NotificationCenter.default.post(
            name: NSNotification.Name("NewChatMessageReceived"),
            object: nil,
            userInfo: ["roomId": data.roomId]
        )
    }
    
    // 채팅방으로 네비게이션
    private func navigateToChat(roomId: String) {
        // SceneDelegate 또는 현재 활성 Scene을 통해 채팅방으로 이동
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToChat"),
                object: nil,
                userInfo: ["roomId": roomId]
            )
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        print("FCM Registration Token: \(fcmToken)")
        
        // FCM 토큰을 키체인에 저장
        KeyChainManager.shared.save(.fcmToken, value: fcmToken)
        
        // 서버에 FCM 토큰 전송
        sendFCMTokenToServer(fcmToken)
    }
    
    // FCM 토큰을 서버에 전송
    private func sendFCMTokenToServer(_ token: String) {
        // TODO: 서버 API 구현 시 사용
        print("Sending FCM token to server: \(token)")
        
        // 예시: API 호출
        /*
        APIClient.shared.updateFCMToken(token) { result in
            switch result {
            case .success:
                print("FCM token updated successfully")
            case .failure(let error):
                print("Failed to update FCM token: \(error)")
            }
        }
        */
    }
}
