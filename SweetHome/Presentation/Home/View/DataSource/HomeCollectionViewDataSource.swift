//
//  HomeCollectionViewDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit

class HomeCollectionViewDataSource {
    
    private weak var delegate: HomeCollectionViewDataSourceDelegate?
    private var dataSource: UICollectionViewDiffableDataSource<HomeViewController.Section, HomeViewController.Item>!
    
    init(collectionView: UICollectionView, delegate: HomeCollectionViewDataSourceDelegate) {
        self.delegate = delegate
        setupDataSource(collectionView: collectionView)
    }
    
    private func setupDataSource(collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<HomeViewController.Section, HomeViewController.Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            return self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            return self?.supplementaryViewProvider(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: HomeViewController.Item) -> UICollectionViewCell? {
        switch item {
        case .estate(let estate, _):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCollectionViewCell.identifier, for: indexPath) as! BannerCollectionViewCell
            cell.configure(with: estate)
            return cell
        case .recentEstate(let estate, _):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentSearchEstateViewCell.identifier, for: indexPath) as! RecentSearchEstateViewCell
            cell.configure(with: estate)
            return cell
        case .hotEstate(let estate, _):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotEstateViewCell.identifier, for: indexPath) as! HotEstateViewCell
            cell.configure(with: estate)
            return cell
        case .topic(let topic):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EstateTopicViewCell.identifier, for: indexPath) as! EstateTopicViewCell
            cell.configure(topic)
            return cell
        case .emptyRecentSearch:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyRecentSearchViewCell.identifier, for: indexPath) as! EmptyRecentSearchViewCell
            return cell
        }
    }
    
    private func supplementaryViewProvider(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BannerFooterView.identifier,
                for: indexPath
            ) as! BannerFooterView
            return footer
        } else if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EstateSectionHeaderView.identifier,
                for: indexPath
            ) as! EstateSectionHeaderView
            
            guard let delegate = delegate else { return header }
            
            let section = HomeViewController.Section.allCases[indexPath.section]
            switch section {
            case .recentSearchEstate:
                if delegate.isRecentEstatesEmpty() {
                    header.configure(title: "최근 검색 매물", hideViewAll: true)
                } else {
                    header.configure(title: "최근 검색 매물") {
                        delegate.viewAllTapped()
                    }
                }
            case .hotEstate:
                header.configure(title: "HOT 매물") {
                    delegate.hotEstateViewAllTapped()
                }
            case .topic:
                header.configure(title: "오늘의 부동산 TOPIC", hideViewAll: true)
            default:
                break
            }
            return header
        }
        return nil
    }
    
    func updateSnapshot(
        bannerItems: [HomeViewController.Item],
        recentItems: [HomeViewController.Item],
        hotItems: [HomeViewController.Item] = [],
        topicItems: [HomeViewController.Item] = []
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeViewController.Section, HomeViewController.Item>()
        snapshot.appendSections(HomeViewController.Section.allCases)
        
        // Banner items
        snapshot.appendItems(bannerItems, toSection: .banner)
        
        // Recent search estate items
        snapshot.appendItems(recentItems, toSection: .recentSearchEstate)
        
        // Hot estate items
        snapshot.appendItems(hotItems, toSection: .hotEstate)
        
        // Topic items
        snapshot.appendItems(topicItems, toSection: .topic)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - HomeCollectionViewDataSourceDelegate
protocol HomeCollectionViewDataSourceDelegate: AnyObject {
    func isRecentEstatesEmpty() -> Bool
    func viewAllTapped()
    func hotEstateViewAllTapped()
}
