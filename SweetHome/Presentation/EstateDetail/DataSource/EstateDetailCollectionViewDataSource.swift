//
//  EstateDetailCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit

class EstateDetailCollectionViewDataSource {
    
    private var dataSource: UICollectionViewDiffableDataSource<EstateDetailViewController.Section, EstateDetailViewController.Item>!
    private var likeCount: Int = 0
    
    init(collectionView: UICollectionView) {
        setupDataSource(collectionView: collectionView)
    }
    
    private func setupDataSource(collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<EstateDetailViewController.Section, EstateDetailViewController.Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            return self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
        }
        
        /// - Footer 설정
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            return self?.supplementaryViewProvider(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: EstateDetailViewController.Item) -> UICollectionViewCell? {
        switch item {
        case .image(let imageUrl, _):
            /// - 매물 이미지 셀 구성
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateDetailBannerCell.identifier, for: indexPath) as! EstateDetailBannerCell
            cell.configure(with: imageUrl)
            return cell
        case .topInfo(let detail):
            /// - 매물 상세 정보 셀 구성
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateDetailTopCell.identifier, for: indexPath) as! EstateDetailTopCell
            cell.configure(detail)
            return cell
        }
    }
    
    private func supplementaryViewProvider(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EstateDetailBannerFooterView.identifier,
                for: indexPath
            ) as! EstateDetailBannerFooterView
            
            /// - Banner 섹션의 Footer인 경우 likeCount 텍스트 설정
            if EstateDetailViewController.Section.allCases[indexPath.section] == .banner {
                footer.configure(with: likeCount)
            }
            
            return footer
        default:
            return nil
        }
    }
    
    func updateSnapshot(bannerItems: [EstateDetailViewController.Item], likeCount: Int = 0) {
        /// - likeCount 저장
        self.likeCount = likeCount
        
        /// - DiffableDataSource 스냅샷 생성 및 업데이트
        var snapshot = NSDiffableDataSourceSnapshot<EstateDetailViewController.Section, EstateDetailViewController.Item>()
        snapshot.appendSections(EstateDetailViewController.Section.allCases)
        
        /// - Banner 섹션에 이미지 아이템들 추가
        snapshot.appendItems(bannerItems, toSection: .banner)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func updateTopInfoSnapshot(topInfoItem: EstateDetailViewController.Item) {
        var snapshot = dataSource.snapshot()
        
        /// - topInfo 섹션의 기존 아이템들 제거
        let existingItems = snapshot.itemIdentifiers(inSection: .topInfo)
        if !existingItems.isEmpty {
            snapshot.deleteItems(existingItems)
        }
        
        /// - topInfo 섹션에 새 아이템 추가
        snapshot.appendItems([topInfoItem], toSection: .topInfo)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func getItem(for indexPath: IndexPath) -> EstateDetailViewController.Item? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}
