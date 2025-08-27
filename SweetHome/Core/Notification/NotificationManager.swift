//
//  NotificationManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import CoreData
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

        /// - 현재 채팅방에 있는 경우  -> 알림 미표시
        if let roomId = userInfo["room_id"] as? String {
            let isInTargetRoom = ChatSocketManager.shared.joinedRoomIds.contains(roomId)
            
            if isInTargetRoom {
                completionHandler([])
                return
            }
        }
        
        /// - FCM 메시지 처리 (데이터 업데이트)
        handleFCMMessage(userInfo)
        
        /// - 다른 채팅방이거나 채팅방이 아닌 경우 알림 표시
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
    
    // 채팅 알림 처리
    private func handleChatNotification(_ data: ChatNotificationData) {
        // 현재 해당 채팅방에 접속해 있는지 확인
        let isInTargetRoom = ChatSocketManager.shared.joinedRoomIds.contains(data.roomId)
        
        if isInTargetRoom {
            // 소켓으로 이미 메시지를 받았으므로 푸시 알림 처리하지 않음
            print("소켓으로 메시지 수신 중이므로 푸시 알림 무시: \(data.roomId)")
            return
        }
        
        print("   - 채팅방에 없으므로 푸시 알림 처리 시작")
        
        // 1. 해당 채팅방의 마지막 메시지 정보 업데이트 (실제 메시지는 저장하지 않음)
        updateChatRoomLastMessage(data: data)
        
        print("   - ✅ 채팅 알림 처리 완료")
    }
    
    // 채팅방의 마지막 푸시 메시지 정보 업데이트
    private func updateChatRoomLastMessage(data: ChatNotificationData) {
        print("📝 [마지막 메시지 업데이트] roomId: \(data.roomId)")
        
        // CoreData 백그라운드 컨텍스트를 직접 사용
        CoreDataStack.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            // Merge 정책 설정 - 외부 변경사항을 우선으로 병합
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            backgroundContext.automaticallyMergesChangesFromParent = true
            
            do {
                // 1. 채팅방 확인/생성
                let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", data.roomId)
                
                var chatRoom: SweetHome.CDChatRoom
                if let existingRoom = try backgroundContext.fetch(roomFetchRequest).first {
                    chatRoom = existingRoom
                } else {
                    // 채팅방이 없으면 생성 (푸시로만 온 경우)
                    chatRoom = SweetHome.CDChatRoom(context: backgroundContext)
                    chatRoom.roomId = data.roomId
                    chatRoom.createdAt = Date()
                    chatRoom.updatedAt = Date()
                    chatRoom.unreadCount = 0
                }
                
                // 2. 채팅방 업데이트
                let currentDate = Date()
                chatRoom.updatedAt = currentDate
                chatRoom.lastPushMessage = data.message  // 푸시 메시지 저장
                chatRoom.lastPushMessageDate = currentDate  // 푸시 메시지 날짜 저장
                
                // 3. 안읽음 카운트 증가
                chatRoom.unreadCount += 1
                
                print("   - 새 푸시 메시지: \(data.message)")
                print("   - 안읽음 카운트: \(chatRoom.unreadCount)")
                
                // 4. 저장
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("   - ✅ CoreData 직접 저장 성공")
                    
                    // 메인 스레드에서 UI 업데이트
                    DispatchQueue.main.async { [weak self] in
                        NotificationCenter.default.post(
                            name: .Chat.newMessageReceived,
                            object: nil,
                            userInfo: ["roomId": data.roomId, "message": data.message]
                        )
                        
                        // 앱 배지 카운트 업데이트
                        self?.updateAppBadgeCount()
                    }
                } else {
                    print("   - 변경사항 없음, 저장 건너뛰기")
                }
                
            } catch {
                print("   - ❌ CoreData 직접 저장 실패: \(error)")
                
                // 실패한 경우에도 최소한 UI 업데이트
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .Chat.newMessageReceived,
                        object: nil,
                        userInfo: ["roomId": data.roomId, "message": data.message]
                    )
                }
            }
        }
    }
    
    /// - 채팅방의 메세지를 읽음 처리함(채팅방 진입 시 호출)
    func markRoomAsRead(_ roomId: String) {
        print("📖 [읽음 처리] 채팅방 읽음 처리 시작: \(roomId)")
        
        // 메인 컨텍스트에서 직접 처리하여 충돌 방지
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let mainContext = CoreDataStack.shared.context
            
            do {
                // 채팅방 조회
                let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                
                if let chatRoom = try mainContext.fetch(roomFetchRequest).first {
                    // 안읽음 카운트 리셋
                    chatRoom.unreadCount = 0
                    // lastPushMessage 클리어 (이제 실제 채팅 메시지가 최신이므로)
                    chatRoom.lastPushMessage = nil
                    chatRoom.lastPushMessageDate = nil
                    chatRoom.updatedAt = Date()
                    
                    if mainContext.hasChanges {
                        try mainContext.save()
                        print("   - ✅ 읽음 처리 및 lastPushMessage 클리어 완료")
                        
                        // 앱 배지 카운트 업데이트
                        self.updateAppBadgeCount()
                        
                        // UI 업데이트 알림
                        NotificationCenter.default.post(
                            name: .Chat.newMessageReceived,
                            object: nil,
                            userInfo: ["roomId": roomId]
                        )
                    }
                }
                
            } catch {
                print("   - ❌ 읽음 처리 실패: \(error)")
                
                // 실패해도 최소한 UI 업데이트는 트리거
                NotificationCenter.default.post(
                    name: .Chat.newMessageReceived,
                    object: nil,
                    userInfo: ["roomId": roomId]
                )
            }
        }
    }
    /// - 백그라운드에서 채팅 알림 처리
    func handleBackgroundChatNotification(_ userInfo: [AnyHashable: Any]) {
        guard let chatData = parseChatNotification(userInfo) else { return }
        
        print("🌙 [백그라운드] 채팅 알림 처리: \(chatData.roomId)")
        
        // 백그라운드에서도 동일한 처리 (마지막 푸시 메시지 업데이트 + 안읽음 카운트 증가)
        updateChatRoomLastMessage(data: chatData)
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
