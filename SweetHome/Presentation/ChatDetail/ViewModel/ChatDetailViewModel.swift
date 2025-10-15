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
    private let useCase: ChatDetailUseCase
    private let socketManager: ChatSocketManager = { return ChatSocketManager.shared }()
    private let chatMessagesRelay = BehaviorSubject<[LastChat]>(value: [])
    private let otherUserNameRelay = BehaviorSubject<String?>(value: nil)
    private let uploadedFilesRelay = BehaviorSubject<[String]>(value: [])

    init(useCase: ChatDetailUseCase = ChatDetailUseCaseImpl(
        repository: ChatDetailRepositoryImpl()
    )) {
        self.useCase = useCase
        _ = socketManager
    }
    
    struct Input {
        let onAppear: Observable<Void>
        let roomId: String
        let sendMessage: Observable<String>
        let sendPhotos: Observable<Void>
        let selectedPhotos: Observable<[Data]>
        let selectedVoice: Observable<VoiceMessageData>
        let viewWillDisappear: Observable<Void>
    }


    enum FileType {
        case photo(Data)
        case voice(VoiceMessageData)

        var data: Data {
            switch self {
            case .photo(let data):
                return data
            case .voice(let voiceData):
                return voiceData.audioData
            }
        }

        var fileName: String {
            let userId = KeyChainManager.shared.read(.userID) ?? ""
            let timestamp = Int(Date().timeIntervalSince1970)

            switch self {
            case .photo:
                return "\(userId)_\(timestamp).jpg"
            case .voice(let voiceData):
                return voiceData.generatedFileName
            }
        }

        var mimeType: String {
            switch self {
            case .photo:
                return "image/jpeg"
            case .voice:
                return "audio/mp4"
            }
        }

        var messageContent: String {
            switch self {
            case .photo:
                return "사진"
            case .voice:
                return "음성메시지"
            }
        }
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
                return self.useCase.loadMessagesWithIncrementalSync(roomId: input.roomId)
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
                return self.useCase.sendMessage(
                    roomId: input.roomId,
                    content: message,
                    files: files.isEmpty ? nil : files
                )
                .map { _ in
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
                let newMessage = socketMessage.toDomain()
                self?.useCase.handleNewSocketMessage(newMessage)
                    .subscribe(onNext: { [weak self] updatedMessages in
                        self?.chatMessagesRelay.onNext(updatedMessages)
                    })
                    .disposed(by: self?.disposeBag ?? DisposeBag())
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
                let fileTypes = imageDatas.map { FileType.photo($0) }
                return self.useCase.uploadFilesAndSendMessage(roomId: input.roomId, fileTypes: fileTypes)
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { _ in
                photosUploadedRelay.onNext(())
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)

        input.selectedVoice
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] voiceData -> Observable<Void> in
                guard let self else { return .empty() }
                let fileType = FileType.voice(voiceData)
                return self.useCase.uploadFilesAndSendMessage(roomId: input.roomId, fileTypes: [fileType])
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
        useCase.performIncrementalSync(roomId: roomId)
            .subscribe(onNext: {
                print("   - 백그라운드 증분 동기화 완료")
            }, onError: { error in
                print("   - 백그라운드 증분 동기화 실패: \(error)")
            })
            .disposed(by: disposeBag)
        
        print("   - ✅ 채팅방 퇴장 처리 완료")
    }
    
    private func updateOtherUserName(from messages: [LastChat]) {
        let otherUserName = useCase.extractOtherUserName(from: messages)
        otherUserNameRelay.onNext(otherUserName)
    }
}

