//
//  ChatDetailCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit

final class ChatDetailCollectionViewDataSource {
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, LastChat>!
    private let currentUserId = KeyChainManager.shared.read(.userID) ?? ""
    private let calendar = Calendar.current
    
    enum Section {
        case messages
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        setupDataSource()
    }
    
    /// - 메시지 목록 변경사항을 스냅샷에 반영하는 함수
    func updateSnapshot(with messages: [LastChat]) {
        let currentSnapshot = dataSource.snapshot()
        
        // 빈 스냅샷이거나 메시지가 적어진 경우 전체 갱신
        guard currentSnapshot.sectionIdentifiers.contains(.messages) else {
            applyFullSnapshot(messages)
            return
        }
        
        let currentMessages = currentSnapshot.itemIdentifiers(inSection: .messages)
        
        if messages.count > currentMessages.count {
            // 새 메시지 추가
            let newMessages = Array(messages.suffix(messages.count - currentMessages.count))
            addNewMessages(newMessages, currentMessages: currentMessages)
        } else {
            // 전체 갱신 (메시지 삭제, 순서 변경 등)
            applyFullSnapshot(messages)
        }
    }
}
//MARK: - DataSource Private Method
private extension ChatDetailCollectionViewDataSource {
    /// - 채팅 메시지 셀을 구성하고 데이터소스를 설정하는 함수
    func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, LastChat>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, message in
            guard let self = self else { return UICollectionViewCell() }
            
            let isMyMessage = message.sender.userId == self.currentUserId
            let shouldShowTime = self.shouldShowTime(for: message, at: indexPath)
            let shouldShowProfile = self.shouldShowProfile(for: message, at: indexPath)
            
            
            let hasFiles = !message.attachedFiles.isEmpty
            
            if isMyMessage {
                if hasFiles {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "MyMessageFileCell",
                        for: indexPath
                    ) as! MyMessageFileCell
                    cell.configure(with: message, shouldShowTime: shouldShowTime)
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "MyMessageCell",
                        for: indexPath
                    ) as! MyMessageCell
                    cell.configure(with: message, shouldShowTime: shouldShowTime)
                    return cell
                }
            } else {
                if hasFiles {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "OtherMessageFileCell",
                        for: indexPath
                    ) as! OtherMessageFileCell
                    cell.configure(with: message, shouldShowTime: shouldShowTime, shouldShowProfile: shouldShowProfile)
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "OtherMessageCell",
                        for: indexPath
                    ) as! OtherMessageCell
                    cell.configure(with: message, shouldShowTime: shouldShowTime, shouldShowProfile: shouldShowProfile)
                    return cell
                }
            }
        }
    }
    
    /// - 메시지의 시간 표시 여부를 결정
    func shouldShowTime(for message: LastChat, at indexPath: IndexPath) -> Bool {
        let messages = dataSource.snapshot().itemIdentifiers(inSection: .messages)
    
        guard indexPath.item < messages.count else { return true }
        /// - 마지막 메시지는 항상 시간 표시
        guard indexPath.item < messages.count - 1 else { return true }
        
        let nextMessage = messages[indexPath.item + 1]

        return !isContinuousMessage(current: message, next: nextMessage)
    }
    
    /// - 상대방 메시지의 프로필 표시 여부를 결정하는 함수
    func shouldShowProfile(for message: LastChat, at indexPath: IndexPath) -> Bool {
        /// - 내 메시지는 프로필이 없기 때문에 false 반환
        guard message.sender.userId != currentUserId else { return false }
        
        /// - 같은 분의 첫 번째 메시지는 항상 프로필 표시
        guard indexPath.item > 0 else { return true }
        
        let messages = dataSource.snapshot().itemIdentifiers(inSection: .messages)
        guard indexPath.item < messages.count else { return true }
        
        let previousMessage = messages[indexPath.item - 1]

        return !isContinuousMessage(current: previousMessage, next: message)
    }
    
    /// - 두 메시지가 연속된 메시지인지 체크
    func isContinuousMessage(current: LastChat, next: LastChat) -> Bool {
        let isSameSender = current.sender.userId == next.sender.userId
        let isSameMinute = calendar.isDate(current.createdAt, equalTo: next.createdAt, toGranularity: .minute)
        return isSameSender && isSameMinute
    }
    
    /// - 전체 메시지를 새로 로드하여 스냅샷을 적용
    func applyFullSnapshot(_ messages: [LastChat]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, LastChat>()
        snapshot.appendSections([.messages])
        snapshot.appendItems(messages, toSection: .messages)
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    /// - 새로운 메시지들을 기존 목록에 추가
    func addNewMessages(_ newMessages: [LastChat], currentMessages: [LastChat]) {
        var snapshot = dataSource.snapshot()
        
        snapshot.appendItems(newMessages, toSection: .messages)
        
        /// - 마지막 기존 메시지의 시간 표시 상태가 변경될 가능성이 있기 때문에 reload
        if let lastExisting = currentMessages.last {
            snapshot.reloadItems([lastExisting])
        }
        
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    /// - 채팅 화면을 맨 아래로 스크롤
    func scrollToBottom() {
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { return }
        
        let lastIndexPath = IndexPath(item: numberOfItems - 1, section: 0)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        }
    }
}
