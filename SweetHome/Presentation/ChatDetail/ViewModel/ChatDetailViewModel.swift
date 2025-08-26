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
    
    init() {
        _ = socketManager
    }
    
    struct Input {
        let onAppear: Observable<Void>
        let roomId: String
        let sendMessage: Observable<String>
        let viewWillDisappear: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let chatMessages: Driver<[LastChat]>
        let error: Driver<SHError>
        let messageSent: Driver<Void>
        let socketConnectionStatus: Driver<SocketConnectionStatus>
        let otherUserName: Driver<String?>
    }
    
    func transform(input: Input) -> Output {
        
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let errorRelay = PublishSubject<SHError>()
        let messageSentRelay = PublishSubject<Void>()
        
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
                // 채팅방 진입 시 모든 메시지를 읽음 처리
                if let lastMessage = messages.last {
                    self?.localRepository.markMessagesAsRead(for: input.roomId, upTo: lastMessage.chatId)
                        .subscribe()
                        .disposed(by: self?.disposeBag ?? DisposeBag())
                    
                    // NotificationManager에도 알림
                    NotificationManager.shared.markRoomAsRead(input.roomId)
                }
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
                let sendChat = SendChat(content: message, files: nil)
                return self.apiClient.requestObservable(ChatEndpoint.sendMessage(room_id: input.roomId, model: sendChat))
                    .map { (_: LastChatResponse) in
                        // HTTP 응답은 성공 여부만 확인하고, UI 업데이트는 소켓으로만 처리
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
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            chatMessages: chatMessagesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            messageSent: messageSentRelay.asDriver(onErrorDriveWith: .empty()),
            socketConnectionStatus: socketManager.connectionStatus.asDriver(onErrorDriveWith: .empty()),
            otherUserName: otherUserNameRelay.asDriver(onErrorDriveWith: .empty())
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
                self?.socketManager.leaveRoom(roomId: roomId)
            })
            .disposed(by: disposeBag)
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
