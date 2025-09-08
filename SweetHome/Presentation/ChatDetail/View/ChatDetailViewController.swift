//
//  ChatDetailViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI

class ChatDetailViewController: BaseViewController {
    private let viewModel = ChatDetailViewModel()
    private let roomId: String
    private let refreshControl = UIRefreshControl()
    private let selectedPhotosRelay = PublishSubject<[Data]>()
    
    private let navigationBar = SHNavigationBar()
    
    private lazy var collectionView: UICollectionView = {
        let layout = layoutManager.createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(MyMessageCell.self, forCellWithReuseIdentifier: "MyMessageCell")
        cv.register(OtherMessageCell.self, forCellWithReuseIdentifier: "OtherMessageCell")
        cv.register(MyMessageFileCell.self, forCellWithReuseIdentifier: "MyMessageFileCell")
        cv.register(OtherMessageFileCell.self, forCellWithReuseIdentifier: "OtherMessageFileCell")
        cv.keyboardDismissMode = .onDrag
        return cv
    }()
    
    private let chatInputView = ChatDetailInputView()
    
    private lazy var layoutManager = ChatDetailCollectionViewLayout()
    private lazy var dataSourceManager = ChatDetailCollectionViewDataSource(collectionView: collectionView)
    
    private var chatInputViewBottomConstraint: Constraint!
    
    init(roomId: String) {
        self.roomId = roomId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private let viewWillDisappearSubject = PublishSubject<Void>()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearSubject.onNext(())
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        view.addSubviews(navigationBar, collectionView, chatInputView)
    }
    
    override func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(chatInputView.snp.top)
        }
        
        chatInputView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.greaterThanOrEqualTo(48)
            chatInputViewBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
    }
    
    override func bind() {
        let sendMessageText = chatInputView.sendButton.rx.tap
            .withLatestFrom(chatInputView.messageTextView.rx.text.orEmpty)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .do(onNext: { _ in
                self.chatInputView.clearText()
                self.chatInputView.sendButton.isEnabled = false
            })
            .flatMapLatest { message -> Observable<String> in
                return Observable.just(message)
                    .delay(.milliseconds(100), scheduler: MainScheduler.instance)
                    .do(onNext: { _ in
                        self.chatInputView.sendButton.isEnabled = true
                    })
            }
            .share()
        
        let input = ChatDetailViewModel.Input(
            onAppear: .just(()).asObservable(),
            roomId: roomId,
            sendMessage: sendMessageText,
            sendPhotos: chatInputView.addPhotoButton.rx.tap.asObservable(),
            selectedPhotos: selectedPhotosRelay.asObservable(),
            viewWillDisappear: viewWillDisappearSubject.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.chatMessages
            .drive(onNext: { [weak self] messages in
                self?.dataSourceManager.updateSnapshot(with: messages)
            })
            .disposed(by: disposeBag)
        
        output.isLoading
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        
        output.error
            .drive(onNext: { [weak self] error in
                print("에러 발생: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        output.socketConnectionStatus
            .drive(onNext: { [weak self] status in
                self?.updateConnectionStatus(status)
            })
            .disposed(by: disposeBag)
        
        output.otherUserName
            .compactMap { $0 }
            .drive(onNext: { [weak self] name in
                self?.navigationBar.configure(title: name)
            })
            .disposed(by: disposeBag)
        
        output.showPhotoPicker
            .drive(onNext: { [weak self] _ in
                self?.presentPhotoPicker()
            })
            .disposed(by: disposeBag)
        
        
        navigationBar.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillShow(notification)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillHide(notification)
            })
            .disposed(by: disposeBag)
    }
}
//MARK: - Private Method
private extension ChatDetailViewController {
    func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        /// - 키보드의 높이 - bottom Safe Area + message Input bottom Padding
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom + 8
        chatInputViewBottomConstraint.update(offset: -keyboardHeight)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        chatInputViewBottomConstraint.update(offset: 0)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }
    
    func scrollToBottom(animated: Bool) {
        guard collectionView.numberOfSections > 0 else { return }
        let lastSection = collectionView.numberOfSections - 1
        let lastItem = collectionView.numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else { return }
        let indexPath = IndexPath(item: lastItem, section: lastSection)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
    
    func updateConnectionStatus(_ status: SocketConnectionStatus) {
        switch status {
        case .connected:
            print("소켓 연결됨")
        case .connecting:
            print("소켓 연결 중...")
        case .disconnected:
            print("소켓 연결 끊김")
        case .error(let message):
            print("소켓 에러: \(message)")
        }
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 5
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension ChatDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        let selectedPhotos = PublishSubject<[UIImage]>()
        var loadedImages: [UIImage] = []
        let group = DispatchGroup()
        
        for result in results {
            group.enter()
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                defer { group.leave() }
                if let data = data,
                   let downsampledImage = UIImage.downsample(from: data, to: CGSize(width: 1280, height: 1280)) {
                    loadedImages.append(downsampledImage)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            let imageDatas = loadedImages.compactMap { $0.adaptiveCompress(maxSizeBytes: 1024 * 1024) }
            
            /// - 5MB 제한 체크
            let totalSize = imageDatas.reduce(0) { $0 + $1.count }
            let maxSize = 5 * 1024 * 1024
            
            if totalSize > maxSize {
                print("크기를 초과합니다.")
                return
            }
            
            self?.selectedPhotosRelay.onNext(imageDatas)
        }
    }
}
