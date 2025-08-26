//
//  ChatCoreDataRepository.swift
//  SweetHome
//
//  Created by 김민호 on 8/26/25.
//

import CoreData
import Foundation
import RxSwift

protocol ChatLocalRepository {
    // MARK: - Chat Rooms
    func saveChatRoom(_ chatRoom: ChatRoom) -> Observable<Void>
    func fetchChatRooms() -> Observable<[ChatRoom]>
    func updateChatRoomUnreadCount(roomId: String, count: Int) -> Observable<Void>
    func deleteChatRoom(roomId: String) -> Observable<Void>
    
    // MARK: - Chat Messages
    func saveChatMessage(_ message: LastChat) -> Observable<Void>
    func saveChatMessages(_ messages: [LastChat]) -> Observable<Void>
    func fetchChatMessages(for roomId: String) -> Observable<[LastChat]>
    func fetchChatMessages(for roomId: String, limit: Int) -> Observable<[LastChat]>
    func updateMessageReadStatus(chatId: String, isRead: Bool) -> Observable<Void>
    func deleteChatMessages(for roomId: String) -> Observable<Void>
    
    // MARK: - Unread Count Management
    func incrementUnreadCount(for roomId: String) -> Observable<Void>
    func resetUnreadCount(for roomId: String) -> Observable<Void>
    
    // MARK: - Sync Management
    func getLastMessageDate(for roomId: String) -> Observable<Date?>
    func markMessagesAsRead(for roomId: String, upTo lastReadChatId: String) -> Observable<Void>
}

class ChatCoreDataRepository: ChatLocalRepository {
    private let coreDataStack = CoreDataStack.shared
}

// MARK: - 채팅방 관련 메서드
extension ChatCoreDataRepository {
    func saveChatRoom(_ chatRoom: ChatRoom) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    /// - 기존 채팅방이 있는지 확인
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "roomId == %@", chatRoom.roomId)
                    
                    let existingRooms = try context.fetch(fetchRequest)
                    
                    if let existingRoom = existingRooms.first {
                        // 업데이트
                        existingRoom.updatedAt = chatRoom.updatedAt
                        existingRoom.lastChatId = chatRoom.lastChat?.chatId
                        existingRoom.unreadCount = Int32(chatRoom.unreadCount)
                    } else {
                        // 새로 생성
                        _ = chatRoom.toEntity(context: context)
                    }
                    
                    try context.save()
                    
                    DispatchQueue.main.async {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchChatRooms() -> Observable<[ChatRoom]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            let context = self.coreDataStack.context
            let fetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            do {
                let roomEntities = try context.fetch(fetchRequest)
                var chatRooms: [ChatRoom] = []
                
                for roomEntity in roomEntities {
                    // 마지막 메시지 가져오기
                    let lastChat = self.fetchLastMessage(for: roomEntity.roomId ?? "")
                    let chatRoom = roomEntity.toDomain(with: lastChat)
                    chatRooms.append(chatRoom)
                }
                
                observer.onNext(chatRooms)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func updateChatRoomUnreadCount(roomId: String, count: Int) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                    
                    if let room = try context.fetch(fetchRequest).first {
                        room.unreadCount = Int32(count)
                        try context.save()
                        
                        DispatchQueue.main.async {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    } else {
                        DispatchQueue.main.async {
                            observer.onError(NSError(domain: "ChatCoreDataRepository", code: -2, userInfo: [NSLocalizedDescriptionKey: "Chat room not found"]))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteChatRoom(roomId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                    
                    if let room = try context.fetch(fetchRequest).first {
                        context.delete(room)
                        try context.save()
                        
                        DispatchQueue.main.async {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    } else {
                        DispatchQueue.main.async {
                            observer.onCompleted()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
// MARK: - 채팅 메세지 관련 메서드
extension ChatCoreDataRepository {
    func saveChatMessage(_ message: LastChat) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    // 기존 메시지가 있는지 확인
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "chatId == %@", message.chatId)
                    
                    let existingMessages = try context.fetch(fetchRequest)
                    
                    if existingMessages.isEmpty {
                        // 새로 생성
                        let messageEntity = message.toEntity(context: context)
                        
                        // 해당 채팅방과 연결
                        let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                        roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", message.roomId)
                        
                        if let room = try context.fetch(roomFetchRequest).first {
                            messageEntity.chatRoom = room
                        }
                        
                        try context.save()
                    }
                    
                    DispatchQueue.main.async {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func saveChatMessages(_ messages: [LastChat]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    for message in messages {
                        // 기존 메시지가 있는지 확인
                        let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "chatId == %@", message.chatId)
                        
                        let existingMessages = try context.fetch(fetchRequest)
                        
                        if existingMessages.isEmpty {
                            let messageEntity = message.toEntity(context: context)
                            
                            // 해당 채팅방과 연결
                            let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                            roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", message.roomId)
                            
                            if let room = try context.fetch(roomFetchRequest).first {
                                messageEntity.chatRoom = room
                            }
                        }
                    }
                    
                    try context.save()
                    
                    DispatchQueue.main.async {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchChatMessages(for roomId: String) -> Observable<[LastChat]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            let context = self.coreDataStack.context
            let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            do {
                let messageEntities = try context.fetch(fetchRequest)
                let messages = messageEntities.map { $0.toDomain() }
                
                observer.onNext(messages)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func updateMessageReadStatus(chatId: String, isRead: Bool) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "chatId == %@", chatId)
                    
                    if let message = try context.fetch(fetchRequest).first {
                        message.isRead = isRead
                        try context.save()
                        
                        DispatchQueue.main.async {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    } else {
                        DispatchQueue.main.async {
                            observer.onCompleted()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteChatMessages(for roomId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                    
                    let messages = try context.fetch(fetchRequest)
                    for message in messages {
                        context.delete(message)
                    }
                    
                    try context.save()
                    
                    DispatchQueue.main.async {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
// MARK: - 안읽은 메세지 관련 메서드
extension ChatCoreDataRepository {
    func incrementUnreadCount(for roomId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                    
                    if let room = try context.fetch(fetchRequest).first {
                        room.unreadCount += 1
                        try context.save()
                        
                        DispatchQueue.main.async {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    } else {
                        DispatchQueue.main.async {
                            observer.onCompleted()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func resetUnreadCount(for roomId: String) -> Observable<Void> {
        return updateChatRoomUnreadCount(roomId: roomId, count: 0)
    }
}
// MARK: - 동기화 및 읽음처리 관련 메서드
extension ChatCoreDataRepository {
    func getLastMessageDate(for roomId: String) -> Observable<Date?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            let context = self.coreDataStack.context
            let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                if let lastMessage = try context.fetch(fetchRequest).first {
                    observer.onNext(lastMessage.createdAt)
                } else {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func markMessagesAsRead(for roomId: String, upTo lastReadChatId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            self.coreDataStack.performBackgroundTask { context in
                do {
                    // 채팅방의 lastReadChatId 업데이트
                    let roomFetchRequest: NSFetchRequest<SweetHome.CDChatRoom> = SweetHome.CDChatRoom.fetchRequest()
                    roomFetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
                    
                    if let room = try context.fetch(roomFetchRequest).first {
                        room.lastReadChatId = lastReadChatId
                        room.unreadCount = 0
                    }
                    
                    // 해당 메시지까지 읽음 처리
                    let messageFetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
                    messageFetchRequest.predicate = NSPredicate(format: "roomId == %@ AND isRead == NO", roomId)
                    
                    let unreadMessages = try context.fetch(messageFetchRequest)
                    for message in unreadMessages {
                        message.isRead = true
                    }
                    
                    try context.save()
                    
                    DispatchQueue.main.async {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
// MARK: - Private Helpers
extension ChatCoreDataRepository {
    private func fetchLastMessage(for roomId: String) -> LastChat? {
        let context = coreDataStack.context
        let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            if let lastMessageEntity = try context.fetch(fetchRequest).first {
                return lastMessageEntity.toDomain()
            }
        } catch {
            print("Failed to fetch last message: \(error)")
        }
        
        return nil
    }
    
    func fetchChatMessages(for roomId: String, limit: Int) -> Observable<[LastChat]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatCoreDataRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"]))
                return Disposables.create()
            }
            
            let context = self.coreDataStack.context
            let fetchRequest: NSFetchRequest<SweetHome.CDChatMessage> = SweetHome.CDChatMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            do {
                let messageEntities = try context.fetch(fetchRequest)
                let messages = messageEntities.map { $0.toDomain() }.reversed() // 시간순으로 정렬
                
                observer.onNext(Array(messages))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
