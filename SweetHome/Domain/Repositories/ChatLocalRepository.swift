//
//  ChatLocalRepository.swift
//  SweetHome
//
//  Created by 김민호 on 8/26/25.
//

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
    func getLatestMessageForRoom(roomId: String) -> Observable<LastChat?>
}
