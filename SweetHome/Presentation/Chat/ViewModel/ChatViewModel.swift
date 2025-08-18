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
    
    init() {}
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let chatRoomsRelay = BehaviorSubject<[ChatRoom]>(value: [])
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
            .subscribe(onNext: { chatRooms in
                chatRoomsRelay.onNext(chatRooms)
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
}
