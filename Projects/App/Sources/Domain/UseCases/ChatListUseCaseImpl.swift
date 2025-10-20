//
//  ChatListUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - ChatListUseCase의 구현체
public final class ChatListUseCaseImpl: ChatListUseCase {

    // MARK: - Dependencies
    private let repository: ChatListRepository

    // MARK: - Initialization
    public init(repository: ChatListRepository) {
        self.repository = repository
    }

    // MARK: - ChatListUseCase Implementation

    /// - 채팅방 목록 조회 및 로컬 데이터와 병합
    public func fetchChatRoomsWithLocalData() -> Observable<[ChatRoom]> {
        return repository.fetchChatRooms()
            .flatMap { [weak self] serverChatRooms -> Observable<[ChatRoom]> in
                guard let self = self else { return .just(serverChatRooms) }

                return self.repository.fetchLocalChatRooms()
                    .flatMap { localChatRooms -> Observable<[ChatRoom]> in
                        return self.mergeChatRoomsWithLocalData(
                            serverChatRooms: serverChatRooms,
                            localChatRooms: localChatRooms
                        )
                    }
            }
    }

    /// - 채팅방 목록을 로컬 최신 메시지와 병합
    /// - Parameters:
    ///   - serverChatRooms: 서버에서 받은 채팅방 목록
    ///   - localChatRooms: 로컬 채팅방 목록
    public func mergeChatRoomsWithLocalData(
        serverChatRooms: [ChatRoom],
        localChatRooms: [ChatRoom]
    ) -> Observable<[ChatRoom]> {
        let mergeObservables = serverChatRooms.map { chatRoom -> Observable<ChatRoom> in
            return mergeWithLocalLatestMessage(
                chatRoom: chatRoom,
                localChatRooms: localChatRooms
            )
        }

        return Observable.combineLatest(mergeObservables)
    }

    // MARK: - Private Methods

    /// - 개별 채팅방을 로컬 최신 메시지와 병합
    private func mergeWithLocalLatestMessage(
        chatRoom: ChatRoom,
        localChatRooms: [ChatRoom]
    ) -> Observable<ChatRoom> {
        let localRoom = localChatRooms.first(where: { $0.roomId == chatRoom.roomId })

        return repository.getLatestMessage(for: chatRoom.roomId)
            .map { localLatestMessage in
                var finalLastChat = chatRoom.lastChat

                // 1. 로컬 실제 메시지와 서버 lastChat 비교
                if let localMessage = localLatestMessage,
                   let serverLastChat = chatRoom.lastChat {
                    if localMessage.createdAt > serverLastChat.createdAt {
                        finalLastChat = localMessage
                        print("📝 [병합] \(chatRoom.roomId): 로컬 실제 메시지가 더 최신")
                    }
                } else if let localMessage = localLatestMessage, chatRoom.lastChat == nil {
                    finalLastChat = localMessage
                    print("📝 [병합] \(chatRoom.roomId): 서버 lastChat 없음, 로컬 메시지 사용")
                }

                // 2. lastPushMessage가 가장 최신인지 확인
                if let pushMessage = localRoom?.lastPushMessage,
                   let pushDate = localRoom?.lastPushMessageDate,
                   !pushMessage.isEmpty {

                    let currentLastChatDate = finalLastChat?.createdAt ?? Date.distantPast

                    if pushDate > currentLastChatDate {
                        // 푸시 메시지가 가장 최신이면 임시 LastChat 생성
                        finalLastChat = LastChat(
                            chatId: "push_\(UUID().uuidString)",
                            roomId: chatRoom.roomId,
                            content: pushMessage,
                            createdAt: pushDate,
                            updatedAt: pushDate,
                            sender: ChatSender(userId: "", nickname: "", introduction: "", profileImageURL: ""),
                            attachedFiles: []
                        )
                        print("📝 [병합] \(chatRoom.roomId): 푸시 메시지가 가장 최신 (\(pushDate))")
                    }
                }

                return ChatRoom(
                    roomId: chatRoom.roomId,
                    createdAt: chatRoom.createdAt,
                    updatedAt: chatRoom.updatedAt,
                    participants: chatRoom.participants,
                    lastChat: finalLastChat,
                    lastPushMessage: localRoom?.lastPushMessage,
                    lastPushMessageDate: localRoom?.lastPushMessageDate,
                    unreadCount: localRoom?.unreadCount ?? 0
                )
            }
            .catch { [weak self] error in
                print("로컬 최신 메시지 조회 실패: \(error)")
                // 실패 시 기본 병합 로직 사용
                if let localRoom = localRoom {
                    return .just(ChatRoom(
                        roomId: chatRoom.roomId,
                        createdAt: chatRoom.createdAt,
                        updatedAt: chatRoom.updatedAt,
                        participants: chatRoom.participants,
                        lastChat: chatRoom.lastChat,
                        lastPushMessage: localRoom.lastPushMessage,
                        lastPushMessageDate: localRoom.lastPushMessageDate,
                        unreadCount: localRoom.unreadCount
                    ))
                } else {
                    // 로컬에 없으면 저장 후 서버 데이터 사용
                    self?.repository.saveChatRoom(chatRoom)
                        .subscribe()
                        .dispose()
                    return .just(chatRoom)
                }
            }
    }
}
