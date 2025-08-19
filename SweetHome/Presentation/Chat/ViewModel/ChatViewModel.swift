//
//  ChatViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class ChatViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    private let apiClient = ApiClient()
    private let socketRepository = ChatSocketRepository()
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
                self?.refreshChatRoomsFromRealm()
            })
            .disposed(by: disposeBag)
        
        // 앱 포그라운드 진입 시 동기화
        NotificationCenter.default.rx
            .notification(.Chat.syncUnreadCounts)
            .subscribe(onNext: { [weak self] notification in
                self?.refreshChatRoomsFromRealm()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateChatRoomsWithUnreadCounts(_ chatRooms: [ChatRoom]) {
        do {
            let realm = try Realm()
            
            let updatedChatRooms = chatRooms.map { chatRoom in
                if let entity = realm.object(ofType: ChatRoomEntity.self, forPrimaryKey: chatRoom.roomId) {
                    return ChatRoom(
                        roomId: chatRoom.roomId,
                        createdAt: chatRoom.createdAt,
                        updatedAt: chatRoom.updatedAt,
                        participants: chatRoom.participants,
                        lastChat: chatRoom.lastChat,
                        unreadCount: entity.unreadCount
                    )
                } else {
                    return chatRoom
                }
            }
            
            chatRoomsRelay.onNext(updatedChatRooms)
        } catch {
            print("Realm 조회 실패: \(error)")
            chatRoomsRelay.onNext(chatRooms)
        }
    }
    
    private func refreshChatRoomsFromRealm() {
        guard let currentChatRooms = try? chatRoomsRelay.value() else { return }
        updateChatRoomsWithUnreadCounts(currentChatRooms)
    }
}
