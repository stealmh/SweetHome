//
//  CommunityCollectionViewLayout.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit

/// - 커뮤니티 목록 화면의 CompositionalLayout 담당
final class CommunityCollectionViewLayout {

    func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            return self?.createCommunityListSection()
        }
    }

    /// - 커뮤니티 게시글 목록 섹션
    private func createCommunityListSection() -> NSCollectionLayoutSection {
        /// - 아이템 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        /// - 그룹 설정
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        /// - 섹션 설정
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 20,
            bottom: 20,
            trailing: 20
        )

        return section
    }
}