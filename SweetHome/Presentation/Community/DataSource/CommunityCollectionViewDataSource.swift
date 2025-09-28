//
//  CommunityCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit

/// - CommunityCollectionViewDataSource 프로토콜
protocol CommunityCollectionViewDataSourceDelegate: AnyObject {
    func didSelectPost(at indexPath: IndexPath)
    func didTapLike(for postId: String)
}

/// - 커뮤니티 목록 화면의 DiffableDataSource 담당
final class CommunityCollectionViewDataSource {

    enum Section: CaseIterable {
        case community
    }

    enum Item: Hashable {
        case post(CommunityPost)
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private weak var delegate: CommunityCollectionViewDataSourceDelegate?

    init(collectionView: UICollectionView, delegate: CommunityCollectionViewDataSourceDelegate) {
        self.delegate = delegate
        configureDataSource(for: collectionView)
    }

    /// - DataSource 설정
    private func configureDataSource(for collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            switch item {
            case .post(let post):
                return self?.configureCommunityPostCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    post: post
                )
            }
        }
    }

    /// - 커뮤니티 게시글 셀 설정
    private func configureCommunityPostCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        post: CommunityPost
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommunityPostCell.identifier,
            for: indexPath
        ) as! CommunityPostCell

        cell.configure(with: post)
        cell.onLikeTapped = { [weak self] in
            self?.delegate?.didTapLike(for: post.id)
        }

        return cell
    }

    /// - 스냅샷 업데이트
    func updateSnapshot(with posts: [CommunityPost]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.community])

        let items = posts.map { Item.post($0) }
        snapshot.appendItems(items, toSection: .community)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    /// - 특정 인덱스의 아이템 반환
    func getItem(for indexPath: IndexPath) -> Item? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}