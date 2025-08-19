//
//  ChatViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ChatViewController: BaseViewController {
    private let viewModel = ChatViewModel()
    
    private let navigationBar = ChatNavigationBar()
    
    private lazy var collectionView: UICollectionView = {
        let layout = layoutManager.createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ChatRoomCell.self, forCellWithReuseIdentifier: "ChatRoomCell")
        return cv
    }()
    
    private lazy var layoutManager = ChatCollectionViewLayout()
    private lazy var dataSourceManager = ChatCollectionViewDataSource(collectionView: collectionView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubviews(navigationBar, collectionView)
    }
    
    override func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func bind() {
        let input = ChatViewModel.Input(
            onAppear: .just(()).asObservable(),
            searchButtonTapped: navigationBar.searchButton.rx.tap.asObservable(),
            settingsButtonTapped: navigationBar.settingsButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.chatRooms
            .drive(onNext: { [weak self] chatRooms in
                self?.dataSourceManager.updateSnapshot(with: chatRooms)
            })
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { [weak self] error in
                print("에러 발생: \(error.localizedDescription)")
                // TODO: 에러 화면 또는 알럿 표시
            })
            .disposed(by: disposeBag)
        
        output.presentSearch
            .drive(onNext: { [weak self] _ in
                // TODO: 검색 화면 present
                print("검색 버튼 탭됨")
            })
            .disposed(by: disposeBag)
        
        output.presentSettings
            .drive(onNext: { [weak self] _ in
                // TODO: 설정 화면 present
                print("설정 버튼 탭됨")
            })
            .disposed(by: disposeBag)
        
        /// - 채팅방 셀 선택 시 읽음 처리
        collectionView.rx.itemSelected
            .withLatestFrom(output.chatRooms.asObservable()) { indexPath, chatRooms in
                return (indexPath, chatRooms)
            }
            .subscribe(onNext: { [weak self] indexPath, chatRooms in
                guard indexPath.row < chatRooms.count else { return }
                
                let selectedRoom = chatRooms[indexPath.row]
                NotificationManager.shared.markRoomAsRead(selectedRoom.roomId)
                
                // TODO: 채팅방 화면으로 이동
                print("채팅방 선택: \(selectedRoom.roomId)")
            })
            .disposed(by: disposeBag)
    }
}

extension ChatViewController {
    enum Section {
        case main
    }
}
