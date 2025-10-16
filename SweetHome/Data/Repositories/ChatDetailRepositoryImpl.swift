//
//  ChatDetailRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - ChatDetailRepository의 구현체
final class ChatDetailRepositoryImpl: ChatDetailRepository {

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

    // MARK: - ChatDetailRepository Implementation

    /// - 채팅 메시지 목록 조회 (서버)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - nextDate: 다음 페이지 날짜 (증분 동기화용)
    func fetchChatMessages(roomId: String, nextDate: String?) -> Observable<[LastChat]> {
        return apiClient
            .requestObservable(ChatEndpoint.messageRead(room_id: roomId, next: nextDate))
            .map { (response: ChatDetailResponse) -> [LastChat] in
                response.data.compactMap { $0.toDomain() }
            }
    }

    /// - 로컬 채팅 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    func fetchLocalChatMessages(for roomId: String) -> Observable<[LastChat]> {
        return localRepository.fetchChatMessages(for: roomId)
    }

    /// - 채팅 메시지 저장 (로컬)
    /// - Parameter message: 저장할 메시지
    func saveChatMessage(_ message: LastChat) -> Observable<Void> {
        return localRepository.saveChatMessage(message)
    }

    /// - 여러 채팅 메시지 저장 (로컬)
    /// - Parameter messages: 저장할 메시지 목록
    func saveChatMessages(_ messages: [LastChat]) -> Observable<Void> {
        return localRepository.saveChatMessages(messages)
    }

    /// - 마지막 메시지 날짜 조회
    /// - Parameter roomId: 채팅방 ID
    func getLastMessageDate(for roomId: String) -> Observable<Date?> {
        return localRepository.getLastMessageDate(for: roomId)
    }

    /// - 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - content: 메시지 내용
    ///   - files: 첨부 파일 URL 목록
    func sendMessage(roomId: String, content: String, files: [String]?) -> Observable<LastChat> {
        let sendChat = SendChat(content: content, files: files)
        return apiClient
            .requestObservable(ChatEndpoint.sendMessage(room_id: roomId, model: sendChat))
            .map { (response: LastChatResponse) -> LastChat in
                response.toDomain()
            }
    }

    /// - 파일 업로드
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - files: 업로드할 파일 데이터
    func uploadFiles(roomId: String, files: [MultipartFormData]) -> Observable<[String]> {
        return apiClient
            .uploadObservable(ChatEndpoint.chatFiles(room_id: roomId, files: files))
            .map { (response: ChatUploadResponse) -> [String] in
                response.files
            }
    }
}
