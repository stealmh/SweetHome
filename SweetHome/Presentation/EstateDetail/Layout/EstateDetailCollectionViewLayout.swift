//
//  EstateDetailCollectionViewLayout.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit

class EstateDetailCollectionViewLayout {
    func createLayout() -> UICollectionViewCompositionalLayout {
        /// - Layout Configuration 설정 (수평 스크롤)
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            switch EstateDetailViewController.Section.allCases[sectionIndex] {
            case .banner:
                return self.createBannerSection()
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
        /// - 경계 넘김 방지를 위한 여백 제거
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.interGroupSpacing = 0
        
        return section
    }
}
