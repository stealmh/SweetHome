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
    
    enum Section {
        case messages
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        setupDataSource()
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, LastChat>(
            collectionView: collectionView
        ) { collectionView, indexPath, message in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ChatMessageCell",
                for: indexPath
            ) as! ChatMessageCell
            
            cell.configure(with: message)
            return cell
        }
    }
    
    func updateSnapshot(with messages: [LastChat]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, LastChat>()
        snapshot.appendSections([.messages])
        snapshot.appendItems(messages, toSection: .messages)
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { return }
        
        let lastIndexPath = IndexPath(item: numberOfItems - 1, section: 0)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        }
    }
}
