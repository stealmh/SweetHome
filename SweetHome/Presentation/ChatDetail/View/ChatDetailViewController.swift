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

class ChatDetailViewController: BaseViewController {
    private let viewModel = ChatDetailViewModel()
    private let roomId: String
    private let refreshControl = UIRefreshControl()
    
    private let navigationBar = ChatDetailNavigationBar()
    
    private lazy var collectionView: UICollectionView = {
        let layout = layoutManager.createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ChatMessageCell.self, forCellWithReuseIdentifier: "ChatMessageCell")
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
        setupKeyboardObserver()
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
            $0.height.greaterThanOrEqualTo(80)
            chatInputViewBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
    }
    
    override func bind() {
        let sendMessageText = chatInputView.sendButton.rx.tap
            .withLatestFrom(chatInputView.messageTextView.rx.text.orEmpty)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .share()
        
        let input = ChatDetailViewModel.Input(
            onAppear: .just(()).asObservable(),
            roomId: roomId,
            sendMessage: sendMessageText,
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
        
        output.messageSent
            .drive(onNext: { [weak self] _ in
                self?.chatInputView.clearText()
            })
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
        
        navigationBar.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupKeyboardObserver() {
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
    
    private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        chatInputViewBottomConstraint.update(offset: -keyboardFrame.height + view.safeAreaInsets.bottom)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        chatInputViewBottomConstraint.update(offset: 0)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateConnectionStatus(_ status: SocketConnectionStatus) {
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
}
