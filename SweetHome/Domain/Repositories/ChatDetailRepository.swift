//
//  ChatDetailRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 채팅 상세 관련 데이터 접근을 추상화하는 Repository
public protocol ChatDetailRepository {
    /// - 채팅 메시지 목록 조회 (서버)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - nextDate: 다음 페이지 날짜 (증분 동기화용)
    func fetchChatMessages(roomId: String, nextDate: String?) -> Observable<[LastChat]>

    /// - 로컬 채팅 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    func fetchLocalChatMessages(for roomId: String) -> Observable<[LastChat]>

    /// - 채팅 메시지 저장 (로컬)
    /// - Parameter message: 저장할 메시지
    func saveChatMessage(_ message: LastChat) -> Observable<Void>

    /// - 여러 채팅 메시지 저장 (로컬)
    /// - Parameter messages: 저장할 메시지 목록
    func saveChatMessages(_ messages: [LastChat]) -> Observable<Void>

    /// - 마지막 메시지 날짜 조회
    /// - Parameter roomId: 채팅방 ID
    func getLastMessageDate(for roomId: String) -> Observable<Date?>

    /// - 메시지 전송
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - content: 메시지 내용
    ///   - files: 첨부 파일 URL 목록
    func sendMessage(roomId: String, content: String, files: [String]?) -> Observable<LastChat>

    /// - 파일 업로드
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - files: 업로드할 파일 정보 배열
    func uploadFiles(roomId: String, files: [FileUpload]) -> Observable<[String]>
}
