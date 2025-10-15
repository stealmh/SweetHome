//
//  ChatListUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 채팅방 목록 관련 비즈니스 로직을 추상화하는 UseCase
protocol ChatListUseCase {
    /// - 채팅방 목록 조회 및 로컬 데이터와 병합
    func fetchChatRoomsWithLocalData() -> Observable<[ChatRoom]>

    /// - 채팅방 목록을 로컬 최신 메시지와 병합
    /// - Parameters:
    ///   - serverChatRooms: 서버에서 받은 채팅방 목록
    ///   - localChatRooms: 로컬 채팅방 목록
    func mergeChatRoomsWithLocalData(
        serverChatRooms: [ChatRoom],
        localChatRooms: [ChatRoom]
    ) -> Observable<[ChatRoom]>
}
