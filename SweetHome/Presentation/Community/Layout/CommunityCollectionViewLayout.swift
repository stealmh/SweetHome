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
        /// - 아이템 설정 (셀 가로는 슈퍼뷰와 동일)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        /// - 그룹 설정
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        /// - 섹션 설정 (각 항목 간 1의 간격)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 1
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
        )

        return section
    }
}