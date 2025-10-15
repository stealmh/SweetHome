//
//  ChatDetailUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - ChatDetailUseCase의 구현체
final class ChatDetailUseCaseImpl: ChatDetailUseCase {

    // MARK: - Dependencies
    private let repository: ChatDetailRepository
    private let disposeBag = DisposeBag()

    // MARK: - Initialization
    init(repository: ChatDetailRepository) {
        self.repository = repository
    }

    // MARK: - ChatDetailUseCase Implementation

    /// - 채팅 메시지 로드 (로컬 우선 + 증분 동기화)
    /// - Parameter roomId: 채팅방 ID
    func loadMessagesWithIncrementalSync(roomId: String) -> Observable<[LastChat]> {
        return repository.fetchLocalChatMessages(for: roomId)
            .do(onNext: { [weak self] _ in
                // 백그라운드에서 증분 동기화 항상 수행
                self?.performIncrementalSync(roomId: roomId)
                    .subscribe()
                    .disposed(by: self?.disposeBag ?? DisposeBag())
            })
    }

    /// - 증분 동기화 수행
    /// - Parameter roomId: 채팅방 ID
    func performIncrementalSync(roomId: String) -> Observable<Void> {
        return repository.getLastMessageDate(for: roomId)
            .flatMap { [weak self] lastMessageDate -> Observable<Void> in
                guard let self = self else { return .empty() }

                let nextDateString: String? = lastMessageDate.flatMap { date in
                    let formatter = ISO8601DateFormatter()
                    formatter.timeZone = TimeZone(identifier: "UTC")
                    return formatter.string(from: date)
                }

                // 마지막 메시지 날짜 이후 메시지 요청
                return self.repository.fetchChatMessages(roomId: roomId, nextDate: nextDateString)
                    .flatMap { newMessages -> Observable<Void> in
                        guard !newMessages.isEmpty else { return .just(()) }

                        // 새 메시지들 로컬 저장
                        return self.repository.saveChatMessages(newMessages)
                    }
                    .catch { error in
                        // 에러가 발생해도 계속 진행
                        print("증분 동기화 실패: \(error)")
                        return .just(())
                    }
            }
    }

    /// - 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - content: 메시지 내용
    ///   - files: 첨부 파일 URL 목록
    func sendMessage(roomId: String, content: String, files: [String]?) -> Observable<LastChat> {
        return repository.sendMessage(roomId: roomId, content: content, files: files)
    }

    /// - 파일 업로드 및 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - fileTypes: 파일 타입 목록
    func uploadFilesAndSendMessage(roomId: String, fileTypes: [ChatDetailViewModel.FileType]) -> Observable<Void> {
        guard !fileTypes.isEmpty else { return .just(()) }

        let multipartData = prepareMultipartData(from: fileTypes)
        let messageContent = fileTypes.first?.messageContent ?? "파일"

        return repository.uploadFiles(roomId: roomId, files: multipartData)
            .flatMap { [weak self] uploadedFiles -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.repository.sendMessage(roomId: roomId, content: messageContent, files: uploadedFiles)
                    .map { _ in () }
            }
    }

    /// - 새 소켓 메시지 처리
    /// - Parameter message: 소켓으로 받은 메시지
    func handleNewSocketMessage(_ message: LastChat) -> Observable<[LastChat]> {
        return repository.saveChatMessage(message)
            .flatMap { [weak self] _ -> Observable<[LastChat]> in
                guard let self = self else { return .empty() }
                return self.repository.fetchLocalChatMessages(for: message.roomId)
            }
    }

    /// - 다른 사용자 이름 추출
    /// - Parameter messages: 메시지 목록
    func extractOtherUserName(from messages: [LastChat]) -> String? {
        let currentUserId = KeyChainManager.shared.read(.userID) ?? ""
        let otherUserMessage = messages.first { $0.sender.userId != currentUserId }
        return otherUserMessage?.sender.nickname
    }

    // MARK: - Private Methods

    /// - MultipartFormData 준비
    private func prepareMultipartData(from fileTypes: [ChatDetailViewModel.FileType]) -> [MultipartFormData] {
        return fileTypes.enumerated().map { index, fileType in
            var fileName = fileType.fileName

            // 사진의 경우 인덱스 추가
            if case .photo = fileType {
                let userId = KeyChainManager.shared.read(.userID) ?? ""
                let timestamp = Int(Date().timeIntervalSince1970)
                fileName = "\(userId)_\(timestamp)_\(index).jpg"
            }

            return MultipartFormData(
                data: fileType.data,
                name: "files",
                fileName: fileName,
                mimeType: fileType.mimeType
            )
        }
    }
}
