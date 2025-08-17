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
    private var parkingCount: Int = 0
    
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
        case .options(let options):
            /// - 매물 옵션 셀 구성
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateDetailOptionCell.identifier, for: indexPath) as! EstateDetailOptionCell
            cell.configure(with: options)
            return cell
        }
    }
    
    private func supplementaryViewProvider(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EstateSectionHeaderView.identifier,
                for: indexPath
            ) as! EstateSectionHeaderView
            
            /// - Options 섹션의 Header인 경우 "옵션 정보" 텍스트 설정
            if EstateDetailViewController.Section.allCases[indexPath.section] == .options {
                header.configure(title: "옵션 정보", hideViewAll: true)
            }
            
            return header
        case UICollectionView.elementKindSectionFooter:
            let section = EstateDetailViewController.Section.allCases[indexPath.section]
            
            if section == .banner {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: EstateDetailBannerFooterView.identifier,
                    for: indexPath
                ) as! EstateDetailBannerFooterView
                
                footer.configure(with: likeCount)
                return footer
                
            } else if section == .options {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: EstateDetailOptionFooterView.identifier,
                    for: indexPath
                ) as! EstateDetailOptionFooterView
                
                footer.configure(parkingCount: parkingCount)
                return footer
            }
            
            return nil
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
    
    func updateOptionsSnapshot(optionsItem: EstateDetailViewController.Item, parkingCount: Int = 0) {
        /// - parkingCount 저장
        self.parkingCount = parkingCount
        
        var snapshot = dataSource.snapshot()
        
        /// - options 섹션의 기존 아이템들 제거
        let existingItems = snapshot.itemIdentifiers(inSection: .options)
        if !existingItems.isEmpty {
            snapshot.deleteItems(existingItems)
        }
        
        /// - options 섹션에 새 아이템 추가
        snapshot.appendItems([optionsItem], toSection: .options)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func getItem(for indexPath: IndexPath) -> EstateDetailViewController.Item? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}
