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
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 20
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        return textView
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전송", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private lazy var layoutManager = ChatDetailCollectionViewLayout()
    private lazy var dataSourceManager = ChatDetailCollectionViewDataSource(collectionView: collectionView)
    
    private var inputContainerBottomConstraint: Constraint!
    
    init(roomId: String) {
        self.roomId = roomId
        super.init(nibName: nil, bundle: nil)
        print("ChatDetailViewController: init called with roomId: \(roomId)")
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
        
        view.addSubviews(navigationBar, collectionView, inputContainerView)
        inputContainerView.addSubviews(messageTextView, sendButton)
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
            $0.bottom.equalTo(inputContainerView.snp.top)
        }
        
        inputContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.greaterThanOrEqualTo(80)
            inputContainerBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
        
        messageTextView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.greaterThanOrEqualTo(40)
            $0.height.lessThanOrEqualTo(120)
        }
        
        sendButton.snp.makeConstraints {
            $0.leading.equalTo(messageTextView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(messageTextView.snp.bottom)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }
    }
    
    override func bind() {
        let sendMessageText = sendButton.rx.tap
            .withLatestFrom(messageTextView.rx.text.orEmpty)
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
                self?.messageTextView.text = ""
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
        
        inputContainerBottomConstraint.update(offset: -keyboardFrame.height + view.safeAreaInsets.bottom)
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        inputContainerBottomConstraint.update(offset: 0)
        
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
