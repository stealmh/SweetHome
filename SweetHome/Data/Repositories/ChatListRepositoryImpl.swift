//
//  ChatListRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - ChatListRepository의 구현체
final class ChatListRepositoryImpl: ChatListRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol
    private let localRepository: ChatLocalRepository

    // MARK: - Initialization
    init(
        apiClient: ApiClientProtocol = ApiClient.shared,
        localRepository: ChatLocalRepository = ChatCoreDataRepositoryImpl()
    ) {
        self.apiClient = apiClient
        self.localRepository = localRepository
    }

    // MARK: - ChatListRepository Implementation

    /// - 채팅방 목록 조회 (서버)
    func fetchChatRooms() -> Observable<[ChatRoom]> {
        return apiClient
            .requestObservable(ChatEndpoint.listRead)
            .map { (response: ChatRoomListResponse) -> [ChatRoom] in
                response.data.map { $0.toDomain() }
            }
    }

    /// - 로컬 채팅방 목록 조회
    func fetchLocalChatRooms() -> Observable<[ChatRoom]> {
        return localRepository.fetchChatRooms()
    }

    /// - 채팅방의 최신 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    func getLatestMessage(for roomId: String) -> Observable<LastChat?> {
        return localRepository.getLatestMessageForRoom(roomId: roomId)
    }

    /// - 채팅방 저장 (로컬)
    /// - Parameter chatRoom: 저장할 채팅방
    func saveChatRoom(_ chatRoom: ChatRoom) -> Observable<Void> {
        return localRepository.saveChatRoom(chatRoom)
    }
}
