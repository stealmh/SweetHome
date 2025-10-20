//
//  EstateSearchDataSource.swift
//  SweetHome
//
//  Created by 김민호 on 9/14/25.
//

import UIKit

class EstateSearchDataSource {

    enum Section {
        case searchResults
    }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, Estate>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Estate>

    private let collectionView: UICollectionView
    private lazy var dataSource = createDataSource()

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        registerCells()
    }

    private func registerCells() {
        collectionView.register(
            EstateSearchResultCell.self,
            forCellWithReuseIdentifier: EstateSearchResultCell.identifier
        )
    }

    private func createDataSource() -> DataSource {
        return DataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, estate in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EstateSearchResultCell.identifier,
                for: indexPath
            ) as? EstateSearchResultCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: estate)
            return cell
        }
    }

    func apply(estates: [Estate], animated: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.searchResults])
        snapshot.appendItems(estates, toSection: .searchResults)

        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func getDataSource() -> DataSource {
        return dataSource
    }
}