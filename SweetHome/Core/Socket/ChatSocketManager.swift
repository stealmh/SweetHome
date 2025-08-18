//
//  ChatSocketManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RxSwift
import RxCocoa
import SocketIO

class ChatSocketManager {
    static let shared = ChatSocketManager()
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    // MARK: - Subjects
    private let connectionStatusSubject = BehaviorSubject<SocketConnectionStatus>(value: .disconnected)
    private let messageReceivedSubject = PublishSubject<SocketMessage>()
    private let userJoinedSubject = PublishSubject<(roomId: String, user: SocketUser)>()
    private let userLeftSubject = PublishSubject<(roomId: String, userId: String)>()
    private let typingStatusSubject = PublishSubject<SocketTypingStatus>()
    private let errorSubject = PublishSubject<String>()
    
    // MARK: - Configuration
    private let baseURL: String
    private var currentUserId: String?
    private var joinedRooms: Set<String> = []
    
    // MARK: - Initialization
    private init() {
        // TODO: Configuration에서 가져오거나 환경변수에서 설정
        self.baseURL = "http://localhost:3000" // 개발용 URL
        setupSocket()
    }
    
    // MARK: - Socket Setup
    private func setupSocket() {
        guard let url = URL(string: baseURL) else {
            connectionStatusSubject.onNext(.error("Invalid server URL"))
            return
        }
        
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(2),
            .forceWebsockets(true)
        ])
        
        socket = manager?.defaultSocket
        setupEventListeners()
    }
    
    // MARK: - Connection Management
    func connect(userId: String) {
        guard currentUserId != userId else { return }
        
        currentUserId = userId
        connectionStatusSubject.onNext(.connecting)
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        joinedRooms.removeAll()
        currentUserId = nil
        connectionStatusSubject.onNext(.disconnected)
    }
    
    func reconnect() {
        disconnect()
        if let userId = currentUserId {
            connect(userId: userId)
        }
    }
    
    // MARK: - Room Management
    func joinRoom(roomId: String) {
        guard let userId = currentUserId else { return }
        guard !joinedRooms.contains(roomId) else { return }
        
        let request = SocketRoomJoinRequest(roomId: roomId, userId: userId)
        
        do {
            let data = try JSONEncoder().encode(request)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            socket?.emit(SocketEvent.joinRoom.rawValue, dict ?? [:])
            joinedRooms.insert(roomId)
        } catch {
            errorSubject.onNext("Failed to join room: \(error.localizedDescription)")
        }
    }
    
    func leaveRoom(roomId: String) {
        guard let userId = currentUserId else { return }
        guard joinedRooms.contains(roomId) else { return }
        
        let request = SocketRoomJoinRequest(roomId: roomId, userId: userId)
        
        do {
            let data = try JSONEncoder().encode(request)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            socket?.emit(SocketEvent.leaveRoom.rawValue, dict ?? [:])
            joinedRooms.remove(roomId)
        } catch {
            errorSubject.onNext("Failed to leave room: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Management
    func sendMessage(roomId: String, content: String, messageType: MessageType = .text, files: [String]? = nil) {
        guard joinedRooms.contains(roomId) else {
            errorSubject.onNext("Not joined to room: \(roomId)")
            return
        }
        
        let request = SocketMessageRequest(
            roomId: roomId,
            content: content,
            messageType: messageType,
            files: files
        )
        
        do {
            let data = try JSONEncoder().encode(request)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            socket?.emit(SocketEvent.sendMessage.rawValue, dict ?? [:])
        } catch {
            errorSubject.onNext("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Typing Management
    func startTyping(roomId: String) {
        sendTypingStatus(roomId: roomId, isTyping: true)
    }
    
    func stopTyping(roomId: String) {
        sendTypingStatus(roomId: roomId, isTyping: false)
    }
    
    private func sendTypingStatus(roomId: String, isTyping: Bool) {
        guard let userId = currentUserId else { return }
        guard joinedRooms.contains(roomId) else { return }
        
        let request = SocketTypingRequest(roomId: roomId, userId: userId, isTyping: isTyping)
        
        do {
            let data = try JSONEncoder().encode(request)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let event = isTyping ? SocketEvent.startTyping.rawValue : SocketEvent.stopTyping.rawValue
            socket?.emit(event, dict ?? [:])
        } catch {
            errorSubject.onNext("Failed to send typing status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Event Listeners
    private func setupEventListeners() {
        // Connection events
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            self?.connectionStatusSubject.onNext(.connected)
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.connectionStatusSubject.onNext(.disconnected)
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, _ in
            let errorMessage = data.first as? String ?? "Unknown error"
            self?.connectionStatusSubject.onNext(.error(errorMessage))
            self?.errorSubject.onNext(errorMessage)
        }
        
        // Message events
        socket?.on(SocketEvent.receiveMessage.rawValue) { [weak self] data, _ in
            self?.handleMessageReceived(data: data)
        }
        
        // User events
        socket?.on(SocketEvent.userJoined.rawValue) { [weak self] data, _ in
            self?.handleUserJoined(data: data)
        }
        
        socket?.on(SocketEvent.userLeft.rawValue) { [weak self] data, _ in
            self?.handleUserLeft(data: data)
        }
        
        // Typing events
        socket?.on(SocketEvent.userTyping.rawValue) { [weak self] data, _ in
            self?.handleTypingStatus(data: data, isTyping: true)
        }
        
        socket?.on(SocketEvent.userStoppedTyping.rawValue) { [weak self] data, _ in
            self?.handleTypingStatus(data: data, isTyping: false)
        }
    }
    
    // MARK: - Event Handlers
    private func handleMessageReceived(data: [Any]) {
        guard let dict = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(SocketMessage.self, from: jsonData)
            messageReceivedSubject.onNext(message)
        } catch {
            errorSubject.onNext("Failed to parse received message: \(error.localizedDescription)")
        }
    }
    
    private func handleUserJoined(data: [Any]) {
        guard let dict = data.first as? [String: Any],
              let roomId = dict["room_id"] as? String else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            let userData = try decoder.decode(SocketUser.self, from: jsonData)
            userJoinedSubject.onNext((roomId: roomId, user: userData))
        } catch {
            errorSubject.onNext("Failed to parse user joined event: \(error.localizedDescription)")
        }
    }
    
    private func handleUserLeft(data: [Any]) {
        guard let dict = data.first as? [String: Any],
              let roomId = dict["room_id"] as? String,
              let userId = dict["user_id"] as? String else { return }
        
        userLeftSubject.onNext((roomId: roomId, userId: userId))
    }
    
    private func handleTypingStatus(data: [Any], isTyping: Bool) {
        guard let dict = data.first as? [String: Any] else { return }
        
        do {
            var mutableDict = dict
            mutableDict["is_typing"] = isTyping
            
            let jsonData = try JSONSerialization.data(withJSONObject: mutableDict)
            let decoder = JSONDecoder()
            let typingStatus = try decoder.decode(SocketTypingStatus.self, from: jsonData)
            typingStatusSubject.onNext(typingStatus)
        } catch {
            errorSubject.onNext("Failed to parse typing status: \(error.localizedDescription)")
        }
    }
}

// MARK: - Public Observables
extension ChatSocketManager {
    var connectionStatus: Observable<SocketConnectionStatus> {
        return connectionStatusSubject.asObservable()
    }
    
    var messageReceived: Observable<SocketMessage> {
        return messageReceivedSubject.asObservable()
    }
    
    var userJoined: Observable<(roomId: String, user: SocketUser)> {
        return userJoinedSubject.asObservable()
    }
    
    var userLeft: Observable<(roomId: String, userId: String)> {
        return userLeftSubject.asObservable()
    }
    
    var typingStatus: Observable<SocketTypingStatus> {
        return typingStatusSubject.asObservable()
    }
    
    var error: Observable<String> {
        return errorSubject.asObservable()
    }
    
    var isConnected: Bool {
        guard case .connected = try? connectionStatusSubject.value() else { return false }
        return true
    }
    
    var joinedRoomIds: Set<String> {
        return joinedRooms
    }
}
