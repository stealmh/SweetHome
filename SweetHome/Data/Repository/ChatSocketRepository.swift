//
//  ChatSocketRepository.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RxSwift
import RxCocoa

class ChatSocketRepository {
    
    // MARK: - Properties
    private let socketManager = ChatSocketManager.shared
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    init() {
        setupSocketObservers()
    }
    
    private func setupSocketObservers() {
        /// - 새 메시지 수신 감지
        socketManager.messageReceived
            .subscribe(onNext: { response in
                print("Message received: \(response.content)")
            })
            .disposed(by: disposeBag)
        
        /// - 에러 처리
        socketManager.error
            .subscribe(onNext: { error in
                print("Socket error: \(error)")
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
    }
    
    func leaveRoom(roomId: String) {
        socketManager.leaveRoom(roomId: roomId)
    }
}

// MARK: - Public Observables
extension ChatSocketRepository {
    var connectionStatus: Observable<SocketConnectionStatus> {
        return socketManager.connectionStatus
    }
    
    var messageReceived: Observable<LastChatResponse> {
        return socketManager.messageReceived
    }
    
    var error: Observable<String> {
        return socketManager.error
    }
}
