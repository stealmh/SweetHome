//
//  ChatListRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 채팅방 목록 관련 데이터 접근을 추상화하는 Repository
public protocol ChatListRepository {
    /// - 채팅방 목록 조회 (서버)
    func fetchChatRooms() -> Observable<[ChatRoom]>

    /// - 로컬 채팅방 목록 조회
    func fetchLocalChatRooms() -> Observable<[ChatRoom]>

    /// - 채팅방의 최신 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    func getLatestMessage(for roomId: String) -> Observable<LastChat?>

    /// - 채팅방 저장 (로컬)
    /// - Parameter chatRoom: 저장할 채팅방
    func saveChatRoom(_ chatRoom: ChatRoom) -> Observable<Void>
}
