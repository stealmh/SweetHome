//
//  PhotoCollectionView.swift
//  SweetHome
//
//  Created by 김민호 on 8/31/25.
//

import UIKit
import SnapKit

final class PhotoCollectionView: UIView {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(PhotoThumbnailCell.self, forCellWithReuseIdentifier: "PhotoThumbnailCell")
        cv.dataSource = self
        return cv
    }()
    
    private var fileUrls: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        snp.makeConstraints {
            $0.height.equalTo(0)
            $0.width.equalTo(0)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(60),
            heightDimension: .absolute(60)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(200),
            heightDimension: .absolute(60)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 3)
        group.interItemSpacing = .fixed(4)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func configure(with files: [String]) {
        fileUrls = files
        collectionView.reloadData()
        isHidden = files.isEmpty
        
        if !files.isEmpty {
            let rowCount = min(2, (files.count + 2) / 3)
            let height = rowCount * 64
            let columnCount = min(3, files.count)
            let width = columnCount * 64
            
            snp.updateConstraints {
                $0.height.equalTo(height)
                $0.width.equalTo(width)
            }
        } else {
            snp.updateConstraints {
                $0.height.equalTo(0)
                $0.width.equalTo(0)
            }
        }
    }
}

extension PhotoCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(fileUrls.count, 6)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoThumbnailCell", for: indexPath) as! PhotoThumbnailCell
        let fileUrl = fileUrls[indexPath.item]
        cell.configure(with: fileUrl)
        return cell
    }
}

final class PhotoThumbnailCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func configure(with fileUrl: String) {
        imageView.setAuthenticatedImage(with: fileUrl, defaultImageType: .profile)
    }
}
