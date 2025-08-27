//
//  ChatCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit

class ChatCollectionViewDataSource {
    
    private var dataSource: UICollectionViewDiffableDataSource<ChatViewController.Section, ChatRoom>!
    
    init(collectionView: UICollectionView) {
        setupDataSource(collectionView: collectionView)
    }
    
    private func setupDataSource(collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<ChatViewController.Section, ChatRoom>(
            collectionView: collectionView
        ) { collectionView, indexPath, chatRoom in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ChatRoomCell",
                for: indexPath
            ) as! ChatRoomCell
            cell.configure(with: chatRoom)
            return cell
        }
    }
    
    func updateSnapshot(with chatRooms: [ChatRoom]) {
        var snapshot = NSDiffableDataSourceSnapshot<ChatViewController.Section, ChatRoom>()
        snapshot.appendSections([.main])
        snapshot.appendItems(chatRooms, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func getItem(for indexPath: IndexPath) -> ChatRoom? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}