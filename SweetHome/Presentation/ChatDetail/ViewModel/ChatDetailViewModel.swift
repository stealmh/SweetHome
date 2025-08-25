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
    private let socketManager: ChatSocketManager = {
        print("ChatDetailViewModel: Accessing ChatSocketManager.shared")
        return ChatSocketManager.shared
    }()
    private let chatMessagesRelay = BehaviorSubject<[LastChat]>(value: [])
    
    init() {
        print("ChatDetailViewModel: init called")
        // socketManager에 명시적으로 접근하여 초기화 강제
        _ = socketManager
        print("ChatDetailViewModel: socketManager accessed in init")
    }
    
    struct Input {
        let onAppear: Observable<Void>
        let roomId: String
        let sendMessage: Observable<String>
        let refreshTrigger: Observable<Void>
        let viewWillDisappear: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let chatMessages: Driver<[LastChat]>
        let error: Driver<SHError>
        let messageSent: Driver<Void>
        let socketConnectionStatus: Driver<SocketConnectionStatus>
    }
    
    func transform(input: Input) -> Output {
        print("ChatDetailViewModel: transform called for roomId: \(input.roomId)")
        // socketManager에 접근하여 초기화 확인
        print("ChatDetailViewModel: socketManager status check - \(socketManager)")
        
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let errorRelay = PublishSubject<SHError>()
        let messageSentRelay = PublishSubject<Void>()
        
        setupSocketConnection(roomId: input.roomId, 
                            onAppear: input.onAppear,
                            viewWillDisappear: input.viewWillDisappear)
        
        let loadMessages = Observable.merge(
            input.onAppear,
            input.refreshTrigger
        )
        
        loadMessages
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<[LastChat]> in
                guard let self else { return .empty() }
                return self.apiClient.requestObservable(ChatEndpoint.messageRead(room_id: input.roomId))
                    .map { (response: ChatDetailResponse) in
                        return response.data.compactMap { $0.toDomain() }
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] messages in
                self?.chatMessagesRelay.onNext(messages)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        input.sendMessage
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] message -> Observable<LastChat> in
                guard let self else { return .empty() }
                let sendChat = SendChat(content: message, files: nil)
                return self.apiClient.requestObservable(ChatEndpoint.sendMessage(room_id: input.roomId, model: sendChat))
                    .map { (response: LastChatResponse) in
                        return response.toDomain()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] sentMessage in
                // HTTP 응답으로 받은 메시지를 즉시 UI에 반영 (낙관적 업데이트)
                guard let currentMessages = try? self?.chatMessagesRelay.value() else { return }
                let updatedMessages = currentMessages + [sentMessage]
                self?.chatMessagesRelay.onNext(updatedMessages)
                
                messageSentRelay.onNext(())
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        socketManager.messageReceived
            .filter { $0.room_id == input.roomId }
            .subscribe(onNext: { [weak self] socketMessage in
                // 소켓으로 받은 메시지를 LastChatResponse로 처리
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
            socketConnectionStatus: socketManager.connectionStatus.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    private func setupSocketConnection(roomId: String, onAppear: Observable<Void>, viewWillDisappear: Observable<Void>) {
        let userId = KeyChainManager.shared.read(.userID) ?? ""
        print("ChatDetailViewModel: setupSocketConnection called with roomId: \(roomId), userId: '\(userId)'")
        print("ChatDetailViewModel: KeyChain userID exists: \(!userId.isEmpty)")
        
        // userId가 비어있으면 에러 처리
        guard !userId.isEmpty else {
            print("ChatDetailViewModel: userID not found in KeyChain")
            return
        }
        
        onAppear
            .subscribe(onNext: { [weak self] _ in
                print("ChatDetailViewModel: onAppear triggered, accessing socketManager")
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
        guard let currentMessages = try? chatMessagesRelay.value() else { return }
        
        // LastChatResponse를 LastChat 도메인 모델로 변환
        let newMessage = response.toDomain()
        
        // 중복 메시지 방지 - chatId로 확인
        let isDuplicate = currentMessages.contains { $0.chatId == newMessage.chatId }
        guard !isDuplicate else { return }
        
        let updatedMessages = currentMessages + [newMessage]
        chatMessagesRelay.onNext(updatedMessages)
    }
    
    private func refreshMessages(roomId: String) {
        apiClient.requestObservable(ChatEndpoint.messageRead(room_id: roomId))
            .map { (response: ChatDetailResponse) in
                return response.data.compactMap { $0.toDomain() }
            }
            .subscribe(onNext: { [weak self] messages in
                self?.chatMessagesRelay.onNext(messages)
            })
            .disposed(by: disposeBag)
    }
}
