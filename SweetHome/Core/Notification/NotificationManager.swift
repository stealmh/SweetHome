//
//  NotificationManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import UserNotifications
import FirebaseMessaging
import RxSwift

class NotificationManager: NSObject {
    
    static let shared = NotificationManager()
    private let localRepository = ChatCoreDataRepository()
    private let disposeBag = DisposeBag()
    
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
        // 현재 해당 채팅방에 접속해 있는지 확인
        let isInTargetRoom = ChatSocketManager.shared.joinedRoomIds.contains(data.roomId)
        
        if isInTargetRoom {
            // 소켓으로 이미 메시지를 받았으므로 푸시 알림 처리하지 않음
            print("소켓으로 메시지 수신 중이므로 푸시 알림 무시: \(data.roomId)")
            return
        }
        
        // 채팅방에 없는 경우에만 푸시 알림 처리
        updateUnreadCount(for: data.roomId)
        
        // 새 메시지로 인한 읽지 않은 개수 업데이트
        NotificationCenter.default.post(
            name: .Chat.newMessageReceived,
            object: nil,
            userInfo: ["roomId": data.roomId]
        )
    }
    
    /// - 안읽음 메시지 카운트 업데이트
    private func updateUnreadCount(for roomId: String) {
        localRepository.incrementUnreadCount(for: roomId)
            .subscribe(onNext: {
                print("안읽음 카운트 업데이트 성공: \(roomId)")
            }, onError: { error in
                print("안읽음 카운트 업데이트 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    /// - 채팅방의 메세지를 읽음 처리함(채팅방 진입 시 호출)
    func markRoomAsRead(_ roomId: String) {
        localRepository.resetUnreadCount(for: roomId)
            .subscribe(onNext: { [weak self] in
                print("채팅방 읽음 처리 완료: \(roomId)")
                // 앱 배지 카운트 업데이트
                self?.updateAppBadgeCount()
            }, onError: { error in
                print("읽음 처리 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    /// - 백그라운드에서 채팅 알림 처리
    func handleBackgroundChatNotification(_ userInfo: [AnyHashable: Any]) {
        guard let chatData = parseChatNotification(userInfo) else { return }
        
        print("백그라운드에서 채팅 알림 처리: \(chatData.roomId)")
        
        // 백그라운드에서도 Realm 업데이트 가능
        updateUnreadCountInBackground(for: chatData.roomId)
        
        // 앱 배지 카운트 업데이트
        updateAppBadgeCount()
    }
    
    /// - 백그라운드에서 안읽음 카운트 업데이트
    private func updateUnreadCountInBackground(for roomId: String) {
        localRepository.incrementUnreadCount(for: roomId)
            .subscribe(onNext: {
                print("백그라운드에서 안읽음 카운트 업데이트 완료: \(roomId)")
            }, onError: { error in
                print("백그라운드 CoreData 업데이트 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    /// - 앱이 포그라운드로 돌아올 때 안읽음 카운트 동기화
    func syncUnreadCountsOnForeground() {
        print("앱 포그라운드 진입 - 안읽음 카운트 동기화 시작")
        
        // ChatViewModel에 동기화 신호 전송
        NotificationCenter.default.post(
            name: .Chat.syncUnreadCounts,
            object: nil
        )
        
        // 앱 배지 카운트 업데이트
        updateAppBadgeCount()
    }
    
    // 앱 배지 카운트 업데이트
    private func updateAppBadgeCount() {
        localRepository.fetchChatRooms()
            .subscribe(onNext: { chatRooms in
                let totalUnreadCount = chatRooms.reduce(0) { $0 + $1.unreadCount }
                
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().setBadgeCount(totalUnreadCount) { error in
                        if let error = error {
                            print("배지 카운트 설정 실패: \(error)")
                        } else {
                            print("배지 카운트 업데이트: \(totalUnreadCount)")
                        }
                    }
                }
            }, onError: { error in
                print("배지 카운트 계산 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    // 채팅방으로 네비게이션
    private func navigateToChat(roomId: String) {
        // SceneDelegate 또는 현재 활성 Scene을 통해 채팅방으로 이동
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .Chat.navigateToChat,
                object: nil,
                userInfo: ["roomId": roomId]
            )
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        
        KeyChainManager.shared.save(.fcmToken, value: fcmToken)
        
        Task {
            do {
                try await sendFCMTokenToServer(fcmToken)
            } catch {
                print("❌ FCM 토큰 서버 전송 실패: \(error)")
            }
        }
    }
    
    private func sendFCMTokenToServer(_ token: String) async throws {
        print("🚀 [SERVER] FCM 토큰 서버 전송 시작: \(token)")
        
        let request = DeviceTokenRequest(deviceToken: token)
        
        do {
            try await NetworkService.shared.noneRequest(UserEndpoint.deviceToken(request))
        } catch {
            throw error
        }
    }
}
