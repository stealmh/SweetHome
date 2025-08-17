//
//  EstateDetailCollectionViewLayout.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit

protocol EstateDetailCollectionViewLayoutDelegate: AnyObject {
    func bannerDidScroll(to page: Int, offset: CGPoint)
}

class EstateDetailCollectionViewLayout {
    weak var delegate: EstateDetailCollectionViewLayoutDelegate?
    
    init(delegate: EstateDetailCollectionViewLayoutDelegate? = nil) {
        self.delegate = delegate
    }
    func createLayout() -> UICollectionViewCompositionalLayout {
        /// - Layout Configuration 설정
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            switch EstateDetailViewController.Section.allCases[sectionIndex] {
            case .banner:
                return self.createBannerSection()
            case .topInfo:
                return self.createTopInfoSection()
            case .options:
                return self.createOptionsSection()
            }
        }
        layout.configuration = config
        return layout
    }
    
    private func createBannerSection() -> NSCollectionLayoutSection {
        /// - 각 이미지가 전체 화면 너비와 높이를 차지하도록 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        /// - 각 그룹이 전체 화면 너비를 차지하도록 설정 (수평 페이징용)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(250)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        /// - Banner 섹션은 수평 페이징으로 설정
        section.orthogonalScrollingBehavior = .groupPaging
        
        /// - 스크롤 변화 감지
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
            guard let self = self else { return }
            
            // 현재 스크롤 offset (point는 현재 스크롤 위치)
            let currentOffset = point
            
            // 가장 많이 보이는 아이템의 인덱스 찾기
            let visibleRect = CGRect(origin: point, size: environment.container.contentSize)
            var mostVisibleItem: NSCollectionLayoutVisibleItem?
            var maxVisibleArea: CGFloat = 0
            
            for item in visibleItems {
                let intersection = item.frame.intersection(visibleRect)
                let visibleArea = intersection.width * intersection.height
                
                if visibleArea > maxVisibleArea {
                    maxVisibleArea = visibleArea
                    mostVisibleItem = item
                }
            }
            
            if let mostVisible = mostVisibleItem {
                let currentIndex = mostVisible.indexPath.item
                
                // 페이지 인덱스와 offset 정보를 함께 전달
                self.delegate?.bannerDidScroll(to: currentIndex, offset: currentOffset)
            }
        }
        
        /// - 경계 넘김 방지를 위한 여백 제거
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.interGroupSpacing = 0
        
        /// - Footer
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(32)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        footer.pinToVisibleBounds = false
        section.boundarySupplementaryItems = [footer]
        
        return section
    }
    
    private func createTopInfoSection() -> NSCollectionLayoutSection {
        /// - TopInfo 섹션의 아이템 크기 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        /// - 그룹 크기 설정
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20)
        
        return section
    }
    
    private func createOptionsSection() -> NSCollectionLayoutSection {
        /// - Options 섹션의 아이템 크기 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        /// - 그룹 크기 설정
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20)
        
        /// - Header 추가
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(32)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        
        /// - Footer 추가 (컨텐츠 크기에 맞춤)
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .estimated(150), // 최소 너비, 컨텐츠에 맞게 자동 조정
            heightDimension: .absolute(32)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottomLeading,
            absoluteOffset: CGPoint(x: 0, y: 0)
        )
        
        section.boundarySupplementaryItems = [header, footer]
        
        return section
    }
}
