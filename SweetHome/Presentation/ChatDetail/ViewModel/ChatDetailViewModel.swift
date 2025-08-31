//
//  ChatDetailViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import Foundation
import RxSwift
import RxCocoa

class ChatDetailViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    private let apiClient = ApiClient()
    private let socketManager: ChatSocketManager = { return ChatSocketManager.shared }()
    private let localRepository = ChatCoreDataRepository()
    private let chatMessagesRelay = BehaviorSubject<[LastChat]>(value: [])
    private let otherUserNameRelay = BehaviorSubject<String?>(value: nil)
    private let uploadedFilesRelay = BehaviorSubject<[String]>(value: [])
    
    init() {
        _ = socketManager
    }
    
    struct Input {
        let onAppear: Observable<Void>
        let roomId: String
        let sendMessage: Observable<String>
        let sendPhotos: Observable<Void>
        let selectedPhotos: Observable<[Data]>
        let viewWillDisappear: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let chatMessages: Driver<[LastChat]>
        let error: Driver<SHError>
        let messageSent: Driver<Void>
        let socketConnectionStatus: Driver<SocketConnectionStatus>
        let otherUserName: Driver<String?>
        let showPhotoPicker: Driver<Void>
        let photosUploaded: Driver<Void>
    }
    
    func transform(input: Input) -> Output {
        
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let errorRelay = PublishSubject<SHError>()
        let messageSentRelay = PublishSubject<Void>()
        let photosUploadedRelay = PublishSubject<Void>()
        
        setupSocketConnection(
            roomId: input.roomId,
            onAppear: input.onAppear,
            viewWillDisappear: input.viewWillDisappear
        )
        
        input.onAppear
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<[LastChat]> in
                guard let self else { return .empty() }
                return self.loadChatMessagesWithIncrementalSync(roomId: input.roomId)
            }
            .do(onNext: { [weak self] messages in 
                isLoadingRelay.onNext(false)
                // 채팅방 진입 시 읽음 처리
                self?.handleRoomEnter(roomId: input.roomId, messages: messages)
            })
            .subscribe(onNext: { [weak self] messages in
                self?.chatMessagesRelay.onNext(messages)
                self?.updateOtherUserName(from: messages)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        input.sendMessage
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] message -> Observable<Void> in
                guard let self else { return .empty() }
                let files = (try? self.uploadedFilesRelay.value()) ?? []
                let sendChat = SendChat(content: message, files: files.isEmpty ? nil : files)
                return self.apiClient.requestObservable(ChatEndpoint.sendMessage(room_id: input.roomId, model: sendChat))
                    .map { (_: LastChatResponse) in
                        // 메시지 전송 후 업로드된 파일 목록 초기화
                        self.uploadedFilesRelay.onNext([])
                        return ()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { _ in
                messageSentRelay.onNext(())
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        socketManager.messageReceived
            .filter { $0.room_id == input.roomId }
            .subscribe(onNext: { [weak self] socketMessage in
                self?.handleNewSocketMessage(socketMessage)
            })
            .disposed(by: disposeBag)
        
        socketManager.error
            .subscribe(onNext: { error in
                //TODO: ERROR TYPE 명시
                //                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        input.selectedPhotos
            .filter { !$0.isEmpty }
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] imageDatas -> Observable<Void> in
                guard let self else { return .empty() }
                return self.uploadPhotos(imageDatas, roomId: input.roomId)
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { _ in
                photosUploadedRelay.onNext(())
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            chatMessages: chatMessagesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            messageSent: messageSentRelay.asDriver(onErrorDriveWith: .empty()),
            socketConnectionStatus: socketManager.connectionStatus.asDriver(onErrorDriveWith: .empty()),
            otherUserName: otherUserNameRelay.asDriver(onErrorDriveWith: .empty()),
            showPhotoPicker: input.sendPhotos.asDriver(onErrorDriveWith: .empty()),
            photosUploaded: photosUploadedRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    private func setupSocketConnection(roomId: String, onAppear: Observable<Void>, viewWillDisappear: Observable<Void>) {
        let userId = KeyChainManager.shared.read(.userID) ?? ""
        guard !userId.isEmpty else { return }
        
        onAppear
            .subscribe(onNext: { [weak self] _ in
                self?.socketManager.connect(userId: userId)
                self?.socketManager.joinRoom(roomId: roomId)
            })
            .disposed(by: disposeBag)
        
        viewWillDisappear
            .subscribe(onNext: { [weak self] _ in
                // 채팅방 퇴장 시 처리
                self?.handleRoomExit(roomId: roomId)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Room Enter/Exit Handling
    
    private func handleRoomEnter(roomId: String, messages: [LastChat]) {
        print("🚪 [채팅방 진입] 채팅방 진입 처리 시작: \(roomId)")
        
        // 채팅방 진입 시 읽음 처리 - NotificationManager에 일임하여 충돌 방지
        if let lastMessage = messages.last {
            print("   - 마지막 메시지까지 읽음 처리: \(lastMessage.chatId)")
            
            // NotificationManager에서 통합 읽음 처리 (메시지 읽음 + 안읽음 카운트 리셋 + lastPushMessage 클리어)
            NotificationManager.shared.markRoomAsRead(roomId)
            print("   - 통합 읽음 처리 완료")
        }
        
        print("   - ✅ 채팅방 진입 처리 완료")
    }
    
    // MARK: - Room Exit Handling
    
    private func handleRoomExit(roomId: String) {
        print("🚪 [채팅방 퇴장] 채팅방 퇴장 처리 시작: \(roomId)")
        
        // 1. 소켓에서 채팅방 퇴장
        socketManager.leaveRoom(roomId: roomId)
        print("   - 소켓 방 퇴장 완료")
        
        // 2. 현재 표시된 메시지들 중 마지막 메시지까지 읽음 처리
        do {
            let currentMessages = try chatMessagesRelay.value()
            if let lastMessage = currentMessages.last {
                print("   - 마지막 메시지까지 읽음 처리: \(lastMessage.chatId)")
                
                // NotificationManager에서 통합 읽음 처리 (충돌 방지)
                NotificationManager.shared.markRoomAsRead(roomId)
                print("   - 통합 읽음 처리 완료")
            }
        } catch {
            print("   - 현재 메시지 목록 가져오기 실패: \(error)")
        }
        
        // 3. 로컬 최신 메시지와 채팅방 목록 동기화
        DispatchQueue.main.async {
            // 채팅방 목록 즉시 새로고침 (로컬 데이터 기반)
            NotificationCenter.default.post(
                name: .Chat.newMessageReceived,
                object: nil,
                userInfo: ["roomId": roomId, "action": "roomExit"]
            )
            print("   - 채팅방 목록 로컬 동기화 트리거 완료")
        }
        
        // 4. 백그라운드에서 증분 동기화 (선택적)
        performIncrementalSync(roomId: roomId)
            .subscribe(onNext: {
                print("   - 백그라운드 증분 동기화 완료")
            }, onError: { error in
                print("   - 백그라운드 증분 동기화 실패: \(error)")
            })
            .disposed(by: disposeBag)
        
        print("   - ✅ 채팅방 퇴장 처리 완료")
    }
    
    private func handleNewSocketMessage(_ response: LastChatResponse) {
        let newMessage = response.toDomain()
        
        localRepository.saveChatMessage(newMessage)
            .flatMap { [weak self] _ -> Observable<[LastChat]> in
                guard let self else { return .empty() }
                return self.localRepository.fetchChatMessages(for: newMessage.roomId)
            }
            .subscribe(onNext: { [weak self] updateMessages in
                self?.chatMessagesRelay.onNext(updateMessages)
            })
            .disposed(by: disposeBag)
    }
    
    private func refreshMessages(roomId: String) {
        // refreshMessages는 더 이상 사용하지 않음 (증분 동기화로 대체)
        performIncrementalSync(roomId: roomId)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func updateOtherUserName(from messages: [LastChat]) {
        let currentUserId = KeyChainManager.shared.read(.userID) ?? ""
        let otherUserMessage = messages.first { $0.sender.userId != currentUserId }
        otherUserNameRelay.onNext(otherUserMessage?.sender.nickname)
    }
    
    // MARK: - 증분 동기화 로직
    
    /// 로컬 데이터 우선 로드 → 서버와 증분 동기화
    private func loadChatMessagesWithIncrementalSync(roomId: String) -> Observable<[LastChat]> {
        return localRepository.fetchChatMessages(for: roomId)
            .do(onNext: { [weak self] localMessages in
                // 백그라운드에서 증분 동기화 항상 수행
                self?.performIncrementalSync(roomId: roomId)
                    .subscribe()
                    .disposed(by: self?.disposeBag ?? DisposeBag())
            })
    }
    
    /// 증분 동기화 수행 (마지막 메시지 날짜 이후 메시지만 가져오기)
    private func performIncrementalSync(roomId: String) -> Observable<Void> {
        return localRepository.getLastMessageDate(for: roomId)
            .flatMap { [weak self] lastMessageDate -> Observable<Void> in
                guard let self else { return .empty() }
                
                let nextDateString: String? = lastMessageDate.flatMap { data in
                    let formatter = ISO8601DateFormatter()
                    formatter.timeZone = TimeZone(identifier: "UTC")
                    return formatter.string(from: data)
                }

                
                // 마지막 메시지 날짜 이후 메시지 요청
                return self.apiClient.requestObservable(ChatEndpoint.messageRead(room_id: roomId, next: nextDateString))
                    .map { (response: ChatDetailResponse) in
                        response.data.compactMap { $0.toDomain() }
                    }
                    .flatMap { newMessages -> Observable<Void> in
                        guard !newMessages.isEmpty else { return .just(()) }
                        
                        // 새 메시지들 로컬 저장
                        return self.localRepository.saveChatMessages(newMessages)
                            .flatMap { _ -> Observable<[LastChat]> in
                                self.localRepository.fetchChatMessages(for: roomId)
                            }
                            .do(onNext: { [weak self] updatedMessages in
                                self?.chatMessagesRelay.onNext(updatedMessages)
                            })
                            .map { _ in () }
                    }
                    .catch { error in
                        // 에러가 발생해도 계속 진행
                        print("증분 동기화 실패: \(error)")
                        return .just(())
                    }
            }
    }
}

/// - upload
private extension ChatDetailViewModel {
    func prepareMultipartData(from imageDatas: [Data]) -> [MultipartFormData] {
        let userId = KeyChainManager.shared.read(.userID) ?? ""
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return imageDatas.enumerated().map { index, imageData in
            let fileName = "\(userId)_\(timestamp)_\(index).jpg"
            return MultipartFormData(
                data: imageData,
                name: "files",
                fileName: fileName,
                mimeType: "image/jpeg"
            )
        }
    }
    
    func uploadFiles(_ multipartData: [MultipartFormData], roomId: String) -> Observable<[String]> {
        return apiClient.uploadObservable(ChatEndpoint.chatFiles(room_id: roomId, files: multipartData))
            .map { (response: ChatUploadResponse) in
                return response.files
            }
    }
    
    func sendPhotoMessage(with files: [String], roomId: String) -> Observable<Void> {
        let sendChat = SendChat(content: "사진", files: files)
        return apiClient.requestObservable(ChatEndpoint.sendMessage(room_id: roomId, model: sendChat))
            .map { (_: LastChatResponse) in () }
    }
    
    func uploadPhotos(_ imageDatas: [Data], roomId: String) -> Observable<Void> {
        guard !imageDatas.isEmpty else { return .just(()) }
        
        let multipartData = prepareMultipartData(from: imageDatas)
        
        return uploadFiles(multipartData, roomId: roomId)
            .flatMap { [weak self] files -> Observable<Void> in
                guard let self else { return .empty() }
                return self.sendPhotoMessage(with: files, roomId: roomId)
            }
    }
}
