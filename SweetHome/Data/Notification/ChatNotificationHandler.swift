//
//  ChatNotificationHandler.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import CoreData
import Foundation

final class ChatNotificationHandler {
    static let shared = ChatNotificationHandler()
    
    private init() {}
    
    func handleChatNotification(_ data: ChatNotificationData) {
        let isInTargetRoom = ChatSocketManager.shared.joinedRoomIds.contains(data.roomId)
        
        if isInTargetRoom {
            print("소켓으로 메시지 수신 중이므로 푸시 알림 무시: \(data.roomId)")
            return
        }
        
        print("   - 채팅방에 없으므로 푸시 알림 처리 시작")
        updateChatRoomLastMessage(data: data)
        print("   - ✅ 채팅 알림 처리 완료")
    }
    
    private func updateChatRoomLastMessage(data: ChatNotificationData) {
        print("📝 [마지막 메시지 업데이트] roomId: \(data.roomId)")
        
        CoreDataStack.shared.performBackgroundTask { backgroundContext in
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            backgroundContext.automaticallyMergesChangesFromParent = true
            
            do {
                let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", data.roomId)
                
                var chatRoom: SweetHome.CDChatRoom
                if let existingRoom = try backgroundContext.fetch(roomFetchRequest).first {
                    chatRoom = existingRoom
                } else {
                    chatRoom = SweetHome.CDChatRoom(context: backgroundContext)
                    chatRoom.roomId = data.roomId
                    chatRoom.createdAt = Date()
                    chatRoom.updatedAt = Date()
                    chatRoom.unreadCount = 0
                }
                
                let currentDate = Date()
                chatRoom.updatedAt = currentDate
                chatRoom.lastPushMessage = data.message
                chatRoom.lastPushMessageDate = currentDate
                chatRoom.unreadCount += 1
                
                print("   - 새 푸시 메시지: \(data.message)")
                print("   - 안읽음 카운트: \(chatRoom.unreadCount)")
                
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("   - ✅ CoreData 직접 저장 성공")
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .Chat.newMessageReceived,
                            object: nil,
                            userInfo: ["roomId": data.roomId, "message": data.message]
                        )
                        
                        BadgeCountManager.shared.updateAppBadgeCount()
                    }
                } else {
                    print("   - 변경사항 없음, 저장 건너뛰기")
                }
                
            } catch {
                print("   - ❌ CoreData 직접 저장 실패: \(error)")
                
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
    
    func markRoomAsRead(_ roomId: String) {
        print("📖 [읽음 처리] 채팅방 읽음 처리 시작: \(roomId)")
        
        DispatchQueue.main.async {
            let mainContext = CoreDataStack.shared.context
            
            do {
                let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                
                if let chatRoom = try mainContext.fetch(roomFetchRequest).first {
                    chatRoom.unreadCount = 0
                    chatRoom.lastPushMessage = nil
                    chatRoom.lastPushMessageDate = nil
                    chatRoom.updatedAt = Date()
                    
                    if mainContext.hasChanges {
                        try mainContext.save()
                        print("   - ✅ 읽음 처리 및 lastPushMessage 클리어 완료")
                        
                        BadgeCountManager.shared.updateAppBadgeCount()
                        
                        NotificationCenter.default.post(
                            name: .Chat.newMessageReceived,
                            object: nil,
                            userInfo: ["roomId": roomId]
                        )
                    }
                }
                
            } catch {
                print("   - ❌ 읽음 처리 실패: \(error)")
                
                NotificationCenter.default.post(
                    name: .Chat.newMessageReceived,
                    object: nil,
                    userInfo: ["roomId": roomId]
                )
            }
        }
    }
    
    func syncUnreadCountsOnForeground() {
        print("앱 포그라운드 진입 - 안읽음 카운트 동기화 시작")
        
        NotificationCenter.default.post(
            name: .Chat.syncUnreadCounts,
            object: nil
        )
        
        BadgeCountManager.shared.updateAppBadgeCount()
    }
}