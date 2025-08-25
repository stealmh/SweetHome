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
    
    // MARK: - Subjects
    private let connectionStatusSubject = BehaviorSubject<SocketConnectionStatus>(value: .disconnected)
    private let messageReceivedSubject = PublishSubject<LastChatResponse>()
    private let errorSubject = PublishSubject<String>()
    
    // MARK: - Configuration
    private let baseURL: String = APIConstants.baseURL
    private var currentUserId: String?
    private var joinedRooms: Set<String> = []
    private var namespaceSockets: [String: SocketIOClient] = [:]
    
    // MARK: - Initialization
    private init() {
        setupSocketManager()
    }
}

// MARK: - Socket Setup
extension ChatSocketManager {
    private func setupSocketManager() {
        guard let url = URL(string: baseURL) else {
            connectionStatusSubject.onNext(.error("Invalid server URL: \(baseURL)"))
            return
        }
        
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(2),
            .forceWebsockets(true),
            .extraHeaders(
                ["SeSacKey": APIConstants.sesacKey, "Authorization": KeyChainManager.shared.read(.accessToken) ?? ""]
            )])
    }
    
    private func getNamespaceSocket(roomId: String) -> SocketIOClient? {
        let namespace = "/chats-\(roomId)"
        
        if let existingSocket = namespaceSockets[namespace] {
            return existingSocket
        }
        
        guard let manager = manager else { return nil }
        
        let socket = manager.socket(forNamespace: namespace)
        namespaceSockets[namespace] = socket
        setupEventListeners(for: socket, roomId: roomId)
        return socket
    }
}

// MARK: - Connection Management
extension ChatSocketManager {
    func connect(userId: String) {
        currentUserId = userId
    }
    
    func disconnect() {
        namespaceSockets.values.forEach { $0.disconnect() }
        namespaceSockets.removeAll()
        joinedRooms.removeAll()
        currentUserId = nil
        connectionStatusSubject.onNext(.disconnected)
    }
}

// MARK: - Room Management
extension ChatSocketManager {
    func joinRoom(roomId: String) {
        guard let userId = currentUserId, !userId.isEmpty else { return }
        guard !joinedRooms.contains(roomId) else { return }
        guard let socket = getNamespaceSocket(roomId: roomId) else { return }
        
        connectionStatusSubject.onNext(.connecting)
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.joinedRooms.insert(roomId)
        }
        
        socket.connect()
    }
    
    func leaveRoom(roomId: String) {
        let namespace = "/chats-\(roomId)"
        guard let socket = namespaceSockets[namespace] else { return }
        
        socket.disconnect()
        namespaceSockets.removeValue(forKey: namespace)
        joinedRooms.remove(roomId)
    }
}

// MARK: - Event Listeners
extension ChatSocketManager {
    private func setupEventListeners(for socket: SocketIOClient, roomId: String) {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.connectionStatusSubject.onNext(.connected)
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.connectionStatusSubject.onNext(.disconnected)
        }
        
        socket.on(clientEvent: .error) { [weak self] data, _ in
            let errorMessage = data.first as? String ?? "Unknown error"
            self?.connectionStatusSubject.onNext(.error(errorMessage))
            self?.errorSubject.onNext(errorMessage)
        }
        
        socket.on("chat") { [weak self] data, _ in
            self?.handleChatReceived(data: data, roomId: roomId)
        }
    }
}

// MARK: - Event Handlers
extension ChatSocketManager {
    private func handleChatReceived(data: [Any], roomId: String) {
        guard let dict = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            var mutableDict = dict
            mutableDict["room_id"] = roomId
            let updatedJsonData = try JSONSerialization.data(withJSONObject: mutableDict)
            
            let response = try decoder.decode(LastChatResponse.self, from: updatedJsonData)
            messageReceivedSubject.onNext(response)
        } catch {
            errorSubject.onNext("Failed to parse chat message: \(error.localizedDescription)")
        }
    }
}

// MARK: - Public Observables
extension ChatSocketManager {
    var connectionStatus: Observable<SocketConnectionStatus> {
        return connectionStatusSubject.asObservable()
    }
    
    var messageReceived: Observable<LastChatResponse> {
        return messageReceivedSubject.asObservable()
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
