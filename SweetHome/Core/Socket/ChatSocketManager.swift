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
    private let tokenManager = TokenManager()
    private var isRefreshingToken = false
    private var pendingReconnections: [String] = []
    
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
    private init() {}
}

// MARK: - Socket Setup
extension ChatSocketManager {
    private func setupSocketManager(with accessToken: String) {
        guard let url = URL(string: baseURL) else {
            connectionStatusSubject.onNext(.error("Invalid server URL: \(baseURL)"))
            return
        }
        
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(2),
            .forceWebsockets(true),
            .extraHeaders(
                ["SeSacKey": APIConstants.sesacKey, "Authorization": accessToken]
            )])
    }
    
    private func getNamespaceSocket(roomId: String) -> SocketIOClient? {
        let namespace = "/chats-\(roomId)"
        
        if let existingSocket = namespaceSockets[namespace] {
            return existingSocket
        }
        
        guard let manager else { return nil }
        
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
        
        let accessToken = KeyChainManager.shared.read(.accessToken) ?? ""
        setupSocketManager(with: accessToken)
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
        guard !joinedRooms.contains(roomId) else {return }
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
            self?.handleSocketError(errorMessage, roomId: roomId)
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
    
    private func handleSocketError(_ errorMessage: String, roomId: String) {
        connectionStatusSubject.onNext(.error(errorMessage))
        errorSubject.onNext(errorMessage)
        
        if isAuthenticationError(errorMessage) && !isRefreshingToken {
            handleTokenExpiration(roomId: roomId)
        }
    }
    
    private func isAuthenticationError(_ error: String) -> Bool {
        let authErrorKeywords = ["401", "403", "unauthorized", "authentication", "token", "expired"]
        let lowercaseError = error.lowercased()
        return authErrorKeywords.contains { lowercaseError.contains($0) }
    }
    
    private func handleTokenExpiration(roomId: String) {
        isRefreshingToken = true
        pendingReconnections.append(roomId)
        
        Task {
            let canRefresh = await tokenManager.startRefresh()
            guard canRefresh else {
                await handleTokenRefreshFailure()
                return
            }
            
            do {
                try await refreshAccessToken()
                await handleTokenRefreshSuccess()
            } catch {
                await handleTokenRefreshFailure()
            }
        }
    }
    
    @MainActor
    private func handleTokenRefreshSuccess() {
        let completions = tokenManager.finishRefresh(success: true)
        isRefreshingToken = false
        
        for completion in completions {
            completion(true)
        }
        
        reconnectPendingRooms()
        pendingReconnections.removeAll()
    }
    
    @MainActor
    private func handleTokenRefreshFailure() {
        let completions = tokenManager.finishRefresh(success: false)
        isRefreshingToken = false
        
        for completion in completions {
            completion(false)
        }
        
        connectionStatusSubject.onNext(.error("Token refresh failed. Please login again."))
        pendingReconnections.removeAll()
    }
    
    private func reconnectPendingRooms() {
        guard let userId = currentUserId else { return }
        
        let accessToken = KeyChainManager.shared.read(.accessToken) ?? ""
        setupSocketManager(with: accessToken)
        
        for roomId in pendingReconnections {
            joinRoom(roomId: roomId)
        }
    }
    
    private func refreshAccessToken() async throws {
        // TODO: Implement token refresh API call
        // This should make an API call to refresh the access token
        // For now, we'll assume the token is handled elsewhere
        throw NSError(domain: "TokenRefresh", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token refresh not implemented"])
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
