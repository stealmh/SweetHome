//
//  ChatSocketRepository.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class ChatSocketRepository {
    
    // MARK: - Properties
    private let socketManager = ChatSocketManager.shared
    private let disposeBag = DisposeBag()
    private let realm: Realm
    
    // MARK: - Subjects
    private let chatRoomsSubject = BehaviorSubject<[ChatRoom]>(value: [])
    private let messagesSubject = BehaviorSubject<[String: [LastChat]]>(value: [:]) // roomId: messages
    private let unreadCountSubject = BehaviorSubject<[String: Int]>(value: [:]) // roomId: count
    
    // MARK: - Initialization
    init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
        
        setupSocketObservers()
    }
    
    // MARK: - Socket Observers
    private func setupSocketObservers() {
        // 새 메시지 수신 시 Realm에 저장
        socketManager.messageReceived
            .subscribe(onNext: { [weak self] socketMessage in
                self?.handleReceivedMessage(socketMessage)
            })
            .disposed(by: disposeBag)
        
        // 연결 상태 변경 감지
        socketManager.connectionStatus
            .subscribe(onNext: { [weak self] status in
                self?.handleConnectionStatusChange(status)
            })
            .disposed(by: disposeBag)
        
        // 에러 처리
        socketManager.error
            .subscribe(onNext: { [weak self] error in
                print("Socket error: \(error)")
                // TODO: 에러 처리 로직
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Connection Management
    func connect(userId: String) {
        socketManager.connect(userId: userId)
    }
    
    func disconnect() {
        socketManager.disconnect()
    }
    
    // MARK: - Room Management
    func joinRoom(roomId: String) {
        socketManager.joinRoom(roomId: roomId)
        loadMessagesFromRealm(roomId: roomId)
    }
    
    func leaveRoom(roomId: String) {
        socketManager.leaveRoom(roomId: roomId)
    }
    
    // MARK: - Message Management
    func sendMessage(roomId: String, content: String, messageType: MessageType = .text, files: [String]? = nil) {
        // 1. 임시 메시지 생성 (로컬에서 즉시 표시용)
        let tempMessage = createTempMessage(roomId: roomId, content: content, messageType: messageType, files: files)
        
        // 2. 로컬 Realm에 저장
        saveMessageToRealm(tempMessage)
        
        // 3. 소켓으로 전송
        socketManager.sendMessage(roomId: roomId, content: content, messageType: messageType, files: files)
    }
    
    // MARK: - Typing Management
    func startTyping(roomId: String) {
        socketManager.startTyping(roomId: roomId)
    }
    
    func stopTyping(roomId: String) {
        socketManager.stopTyping(roomId: roomId)
    }
    
    // MARK: - Data Loading
    func loadChatRooms() {
        let realmChatRooms = realm.objects(ChatRoomEntity.self)
        var chatRooms: [ChatRoom] = []
        
        for roomEntity in realmChatRooms {
            // 각 방의 마지막 메시지 가져오기
            let lastMessage = getLastMessage(for: roomEntity.roomId)
            let chatRoom = roomEntity.toDomain(with: lastMessage)
            chatRooms.append(chatRoom)
        }
        
        chatRoomsSubject.onNext(chatRooms)
    }
    
    private func loadMessagesFromRealm(roomId: String) {
        let realmMessages = realm.objects(ChatMessageEntity.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAt", ascending: true)
        
        let messages = realmMessages.map { $0.toDomain() }
        var currentMessages = (try? messagesSubject.value()) ?? [:]
        currentMessages[roomId] = Array(messages)
        messagesSubject.onNext(currentMessages)
    }
    
    // MARK: - Message Handling
    private func handleReceivedMessage(_ socketMessage: SocketMessage) {
        // 1. SocketMessage를 ChatMessage로 변환
        let chatMessage = socketMessage.toChatMessage()
        
        // 2. Realm에 저장
        saveMessageToRealm(chatMessage)
        
        // 3. 읽지 않은 메시지 개수 업데이트
        updateUnreadCount(roomId: chatMessage.roomId)
    }
    
    private func handleConnectionStatusChange(_ status: SocketConnectionStatus) {
        switch status {
        case .connected:
            // 연결 성공 시 참여중인 방들에 다시 조인
            for roomId in socketManager.joinedRoomIds {
                socketManager.joinRoom(roomId: roomId)
            }
        case .disconnected, .error:
            // 연결 끊어짐 시 처리 로직
            break
        case .connecting:
            break
        }
    }
    
    // MARK: - Realm Operations
    private func saveMessageToRealm(_ message: LastChat) {
        do {
            try realm.write {
                let entity = message.toEntity()
                realm.add(entity, update: .modified)
            }
            
            // UI 업데이트를 위해 메시지 목록 갱신
            var currentMessages = (try? messagesSubject.value()) ?? [:]
            var roomMessages = currentMessages[message.roomId] ?? []
            
            // 중복 제거 후 추가
            if !roomMessages.contains(where: { $0.chatId == message.chatId }) {
                roomMessages.append(message)
                roomMessages.sort { $0.createdAt < $1.createdAt }
                currentMessages[message.roomId] = roomMessages
                messagesSubject.onNext(currentMessages)
            }
        } catch {
            print("Failed to save message to Realm: \(error)")
        }
    }
    
    private func updateUnreadCount(roomId: String) {
        let unreadCount = realm.objects(ChatMessageEntity.self)
            .filter("roomId == %@ AND isRead == false", roomId)
            .count
        
        var currentCounts = (try? unreadCountSubject.value()) ?? [:]
        currentCounts[roomId] = unreadCount
        unreadCountSubject.onNext(currentCounts)
    }
    
    // MARK: - Helper Methods
    private func createTempMessage(roomId: String, content: String, messageType: MessageType, files: [String]?) -> LastChat {
        // TODO: 현재 사용자 정보 가져오기
        let currentUser = getCurrentUser()
        
        return LastChat(
            chatId: UUID().uuidString,
            roomId: roomId,
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            sender: ChatSender(
                userId: currentUser.userId,
                nickname: currentUser.nickname,
                introduction: currentUser.introduction,
                profileImageURL: currentUser.profileImageURL
            ),
            attachedFiles: files ?? []
        )
    }
    
    private func getCurrentUser() -> (userId: String, nickname: String, introduction: String, profileImageURL: String) {
        // TODO: 현재 로그인된 사용자 정보 가져오기 (UserDefaults, Keychain 등에서)
        return (
            userId: "current_user_id",
            nickname: "현재 사용자",
            introduction: "",
            profileImageURL: ""
        )
    }
    
    private func getLastMessage(for roomId: String) -> LastChat {
        let lastMessageEntity = realm.objects(ChatMessageEntity.self)
            .filter("roomId == %@", roomId)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first
        
        if let entity = lastMessageEntity {
            return entity.toDomain()
        } else {
            // 기본 메시지 반환
            return LastChat(
                chatId: UUID().uuidString,
                roomId: roomId,
                content: "새로운 채팅을 시작하세요",
                createdAt: Date(),
                updatedAt: Date(),
                sender: ChatSender(
                    userId: "",
                    nickname: "",
                    introduction: "",
                    profileImageURL: ""
                ),
                attachedFiles: []
            )
        }
    }
}

// MARK: - Public Observables
extension ChatSocketRepository {
    var connectionStatus: Observable<SocketConnectionStatus> {
        return socketManager.connectionStatus
    }
    
    var chatRooms: Observable<[ChatRoom]> {
        return chatRoomsSubject.asObservable()
    }
    
    var messages: Observable<[String: [LastChat]]> {
        return messagesSubject.asObservable()
    }
    
    var unreadCounts: Observable<[String: Int]> {
        return unreadCountSubject.asObservable()
    }
    
    var typingStatus: Observable<SocketTypingStatus> {
        return socketManager.typingStatus
    }
    
    func getMessagesForRoom(roomId: String) -> Observable<[LastChat]> {
        return messagesSubject
            .map { $0[roomId] ?? [] }
            .distinctUntilChanged { $0.count == $1.count }
    }
    
    func getUnreadCountForRoom(roomId: String) -> Observable<Int> {
        return unreadCountSubject
            .map { $0[roomId] ?? 0 }
            .distinctUntilChanged()
    }
}

// MARK: - Extensions
private extension SocketMessage {
    func toChatMessage() -> LastChat {
        return LastChat(
            chatId: id,
            roomId: roomId,
            content: content,
            createdAt: timestamp,
            updatedAt: timestamp,
            sender: ChatSender(
                userId: senderId,
                nickname: senderName,
                introduction: "",
                profileImageURL: senderProfileImage ?? ""
            ),
            attachedFiles: files ?? []
        )
    }
}
