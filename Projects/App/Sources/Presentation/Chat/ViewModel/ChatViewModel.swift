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
    private let useCase: ChatListUseCase
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
    
    init(useCase: ChatListUseCase = ChatListUseCaseImpl(
        repository: ChatListRepositoryImpl()
    )) {
        self.useCase = useCase
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
                return self.useCase.fetchChatRoomsWithLocalData()
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] chatRooms in
                self?.chatRoomsRelay.onNext(chatRooms)
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
    
    private func refreshChatRoomsFromCoreData() {
        print("🔄 [새로고침] 채팅방 목록 로컬 새로고침 시작")

        useCase.fetchChatRoomsWithLocalData()
            .subscribe(onNext: { [weak self] chatRooms in
                self?.chatRoomsRelay.onNext(chatRooms)
                print("   - ✅ 채팅방 목록 로컬 새로고침 완료")
            }, onError: { error in
                print("   - ❌ 채팅방 목록 새로고침 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
}
