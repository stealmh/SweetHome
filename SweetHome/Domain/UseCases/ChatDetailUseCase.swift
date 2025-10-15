//
//  ChatDetailUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 채팅 상세 관련 비즈니스 로직을 추상화하는 UseCase
protocol ChatDetailUseCase {
    /// - 채팅 메시지 로드 (로컬 우선 + 증분 동기화)
    /// - Parameter roomId: 채팅방 ID
    func loadMessagesWithIncrementalSync(roomId: String) -> Observable<[LastChat]>

    /// - 증분 동기화 수행
    /// - Parameter roomId: 채팅방 ID
    func performIncrementalSync(roomId: String) -> Observable<Void>

    /// - 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - content: 메시지 내용
    ///   - files: 첨부 파일 URL 목록
    func sendMessage(roomId: String, content: String, files: [String]?) -> Observable<LastChat>

    /// - 파일 업로드 및 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - fileTypes: 파일 타입 목록
    func uploadFilesAndSendMessage(roomId: String, fileTypes: [ChatDetailViewModel.FileType]) -> Observable<Void>

    /// - 새 소켓 메시지 처리
    /// - Parameter message: 소켓으로 받은 메시지
    func handleNewSocketMessage(_ message: LastChat) -> Observable<[LastChat]>

    /// - 다른 사용자 이름 추출
    /// - Parameter messages: 메시지 목록
    func extractOtherUserName(from messages: [LastChat]) -> String?
}
