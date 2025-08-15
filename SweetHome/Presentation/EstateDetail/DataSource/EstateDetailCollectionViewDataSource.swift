//
//  EstateDetailCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit

class EstateDetailCollectionViewDataSource {
    
    private var dataSource: UICollectionViewDiffableDataSource<EstateDetailViewController.Section, EstateDetailViewController.Item>!
    
    init(collectionView: UICollectionView) {
        setupDataSource(collectionView: collectionView)
    }
    
    private func setupDataSource(collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<EstateDetailViewController.Section, EstateDetailViewController.Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            return self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
        }
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: EstateDetailViewController.Item) -> UICollectionViewCell? {
        switch item {
        case .image(let imageUrl, _):
            /// - 매물 이미지 셀 구성
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateDetailImageCell.identifier, for: indexPath) as! EstateDetailImageCell
            cell.configure(with: imageUrl)
            return cell
        }
    }
    
    func updateSnapshot(bannerItems: [EstateDetailViewController.Item]) {
        /// - DiffableDataSource 스냅샷 생성 및 업데이트
        var snapshot = NSDiffableDataSourceSnapshot<EstateDetailViewController.Section, EstateDetailViewController.Item>()
        snapshot.appendSections(EstateDetailViewController.Section.allCases)
        
        /// - Banner 섹션에 이미지 아이템들 추가
        snapshot.appendItems(bannerItems, toSection: .banner)
        
        /// - 애니메이션 없이 즉시 적용 (페이징 스크롤 방해 방지)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func getItem(for indexPath: IndexPath) -> EstateDetailViewController.Item? {
        return dataSource.itemIdentifier(for: indexPath)
    }
}