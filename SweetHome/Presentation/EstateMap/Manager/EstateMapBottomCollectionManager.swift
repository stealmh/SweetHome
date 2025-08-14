//
//  EstateMapBottomCollectionManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/13/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol EstateMapBottomCollectionManagerDelegate: AnyObject {
    func didSelectEstate(_ estate: EstateGeoLocationDataResponse)
}

class EstateMapBottomCollectionManager: NSObject {
    
    // MARK: - Properties
    weak var delegate: EstateMapBottomCollectionManagerDelegate?
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, EstateGeoLocationDataResponse>!
    
    private let disposeBag = DisposeBag()
    private var currentEstateType: BannerEstateType = .oneRoom
    private var estates: [EstateGeoLocationDataResponse] = []
    
    // MARK: - Section
    enum Section: Int, CaseIterable {
        case main
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Setup Methods
    func setupCollectionView(in parentView: UIView) -> UICollectionView {
        let layout = createCompositionalLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        
        // Register cell
        collectionView.register(EstateMapBottomCell.self, forCellWithReuseIdentifier: EstateMapBottomCell.identifier)
        
        setupDataSource()
        
        return collectionView
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            return self?.createMainSection()
        }
    }
    
    private func createMainSection() -> NSCollectionLayoutSection {
        // Item
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(320),
            heightDimension: .absolute(132)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(320),
            heightDimension: .absolute(132)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        
        return section
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, EstateGeoLocationDataResponse>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, estate in
            guard let self = self else { return UICollectionViewCell() }
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EstateMapBottomCell.identifier,
                for: indexPath
            ) as! EstateMapBottomCell
            
            cell.configure(type: self.currentEstateType, estate)
            return cell
        }
    }
    
    // MARK: - Public Methods
    func updateEstates(_ estates: [EstateGeoLocationDataResponse], estateType: BannerEstateType) {
        self.estates = estates
        self.currentEstateType = estateType
        
        print("📋 Updating data source with \(estates.count) estates")
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, EstateGeoLocationDataResponse>()
        snapshot.appendSections([.main])
        snapshot.appendItems(estates, toSection: .main)
        
        DispatchQueue.main.async { [weak self] in
            self?.dataSource.apply(snapshot, animatingDifferences: true) {
                print("✅ Data source update completed")
            }
        }
    }
    
    func hideCollectionView() {
        print("🙈 Hiding collection view")
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.isHidden = true
        }
    }
    
    func showCollectionView() {
        print("😎 Showing collection view")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.collectionView.isHidden = false
            self.collectionView.superview?.bringSubviewToFront(self.collectionView)
            print("✅ Collection view visibility: \(!self.collectionView.isHidden)")
            print("📝 Collection view frame: \(self.collectionView.frame)")
            print("📝 Collection view bounds: \(self.collectionView.bounds)")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension EstateMapBottomCollectionManager: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < estates.count else { return }
        let selectedEstate = estates[indexPath.row]
        delegate?.didSelectEstate(selectedEstate)
    }
}
