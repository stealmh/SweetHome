//
//  ChatViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RxSwift
import RxCocoa

class ChatViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    private let apiClient = ApiClient()
    private let socketRepository = ChatSocketRepository()
    private let localRepository = ChatCoreDataRepository()
    private let chatRoomsRelay = BehaviorSubject<[ChatRoom]>(value: [])
    
    struct Input {
        let onAppear: Observable<Void>
        let searchButtonTapped: Observable<Void>
        let settingsButtonTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let chatRooms: Driver<[ChatRoom]>
        let error: Driver<SHError>
        let presentSearch: Driver<Void>
        let presentSettings: Driver<Void>
    }
    
    init() {
        observeUnreadCountUpdates()
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let errorRelay = PublishSubject<SHError>()
        
        /// - 채팅방 목록 조회
        input.onAppear
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<[ChatRoom]> in
                guard let self else { return .empty() }
                return self.apiClient.requestObservable(ChatEndpoint.listRead)
                    .map { (response: ChatRoomListResponse) in
                        return response.data.map { $0.toDomain() }
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] chatRooms in
                self?.updateChatRoomsWithUnreadCounts(chatRooms)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            chatRooms: chatRoomsRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            presentSearch: input.searchButtonTapped.asDriver(onErrorDriveWith: .empty()),
            presentSettings: input.settingsButtonTapped.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    // MARK: - Private Methods
    
    private func observeUnreadCountUpdates() {
        // 새 메시지 수신 시 안읽음 카운트 업데이트 감지
        NotificationCenter.default.rx
            .notification(.Chat.newMessageReceived)
            .subscribe(onNext: { [weak self] notification in
                self?.refreshChatRoomsFromCoreData()
            })
            .disposed(by: disposeBag)
        
        // 앱 포그라운드 진입 시 동기화
        NotificationCenter.default.rx
            .notification(.Chat.syncUnreadCounts)
            .subscribe(onNext: { [weak self] notification in
                self?.refreshChatRoomsFromCoreData()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateChatRoomsWithUnreadCounts(_ chatRooms: [ChatRoom]) {
        localRepository.fetchChatRooms()
            .subscribe(onNext: { [weak self] localChatRooms in
                guard let self = self else { return }
                
                // 각 채팅방별로 로컬 최신 메시지와 병합
                let mergeObservables = chatRooms.map { chatRoom -> Observable<ChatRoom> in
                    return self.mergeWithLocalLatestMessage(chatRoom: chatRoom, localChatRooms: localChatRooms)
                }
                
                // 모든 채팅방의 병합이 완료되면 UI 업데이트
                Observable.combineLatest(mergeObservables)
                    .subscribe(onNext: { [weak self] updatedChatRooms in
                        self?.chatRoomsRelay.onNext(updatedChatRooms)
                    }, onError: { [weak self] error in
                        print("채팅방 병합 실패: \(error)")
                        self?.chatRoomsRelay.onNext(chatRooms)
                    })
                    .disposed(by: self.disposeBag)
                
            }, onError: { [weak self] error in
                print("CoreData 조회 실패: \(error)")
                self?.chatRoomsRelay.onNext(chatRooms)
            })
            .disposed(by: disposeBag)
    }
    
    private func mergeWithLocalLatestMessage(chatRoom: ChatRoom, localChatRooms: [ChatRoom]) -> Observable<ChatRoom> {
        // 로컬 채팅방 정보 확인
        let localRoom = localChatRooms.first(where: { $0.roomId == chatRoom.roomId })
        
        // 로컬 최신 메시지 가져오기
        return localRepository.getLatestMessageForRoom(roomId: chatRoom.roomId)
            .map { localLatestMessage in
                var finalLastChat = chatRoom.lastChat
                
                // 1. 로컬 실제 메시지와 서버 lastChat 비교
                if let localMessage = localLatestMessage,
                   let serverLastChat = chatRoom.lastChat {
                    // 로컬 메시지가 더 최신이면 로컬 메시지 사용
                    if localMessage.createdAt > serverLastChat.createdAt {
                        finalLastChat = localMessage
                        print("📝 [병합] \(chatRoom.roomId): 로컬 실제 메시지가 더 최신")
                    }
                } else if let localMessage = localLatestMessage, chatRoom.lastChat == nil {
                    // 서버에 lastChat이 없지만 로컬에 메시지가 있는 경우
                    finalLastChat = localMessage
                    print("📝 [병합] \(chatRoom.roomId): 서버 lastChat 없음, 로컬 메시지 사용")
                }
                
                // 2. lastPushMessage가 가장 최신인지 확인
                if let pushMessage = localRoom?.lastPushMessage,
                   let pushDate = localRoom?.lastPushMessageDate,
                   !pushMessage.isEmpty {
                    
                    let currentLastChatDate = finalLastChat?.createdAt ?? Date.distantPast
                    
                    if pushDate > currentLastChatDate {
                        // 푸시 메시지가 가장 최신이면 임시 LastChat 생성
                        finalLastChat = LastChat(
                            chatId: "push_\(UUID().uuidString)",
                            roomId: chatRoom.roomId,
                            content: pushMessage,
                            createdAt: pushDate,
                            updatedAt: pushDate,
                            sender: ChatSender(userId: "", nickname: "", introduction: "", profileImageURL: ""),
                            attachedFiles: []
                        )
                        print("📝 [병합] \(chatRoom.roomId): 푸시 메시지가 가장 최신 (\(pushDate))")
                    }
                }
                
                return ChatRoom(
                    roomId: chatRoom.roomId,
                    createdAt: chatRoom.createdAt,
                    updatedAt: chatRoom.updatedAt,
                    participants: chatRoom.participants,
                    lastChat: finalLastChat,
                    lastPushMessage: localRoom?.lastPushMessage,
                    lastPushMessageDate: localRoom?.lastPushMessageDate,
                    unreadCount: localRoom?.unreadCount ?? 0
                )
            }
            .catch { error in
                print("로컬 최신 메시지 조회 실패: \(error)")
                // 실패 시 기본 병합 로직 사용
                if let localRoom = localRoom {
                    return .just(ChatRoom(
                        roomId: chatRoom.roomId,
                        createdAt: chatRoom.createdAt,
                        updatedAt: chatRoom.updatedAt,
                        participants: chatRoom.participants,
                        lastChat: chatRoom.lastChat,
                        lastPushMessage: localRoom.lastPushMessage,
                        lastPushMessageDate: localRoom.lastPushMessageDate,
                        unreadCount: localRoom.unreadCount
                    ))
                } else {
                    // 로컬에 없으면 저장 후 서버 데이터 사용
                    self.localRepository.saveChatRoom(chatRoom)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                    return .just(chatRoom)
                }
            }
    }
    
    private func refreshChatRoomsFromCoreData() {
        print("🔄 [새로고침] 채팅방 목록 로컬 새로고침 시작")
        guard let currentChatRooms = try? chatRoomsRelay.value() else { 
            print("   - ❌ 현재 채팅방 목록 가져오기 실패")
            return 
        }
        
        // 새로운 병합 로직 사용 (푸시 메시지 포함)
        updateChatRoomsWithUnreadCounts(currentChatRooms)
        print("   - ✅ 채팅방 목록 로컬 새로고침 완료")
    }
}
