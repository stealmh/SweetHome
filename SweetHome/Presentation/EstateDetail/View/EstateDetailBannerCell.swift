//
//  EstateDetailBannerCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit
import SnapKit

class EstateDetailBannerCell: UICollectionViewCell {
    static let identifier = "EstateDetailBannerCell"
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func configure(with imageUrl: String) {
        imageView.setAuthenticatedImage(with: imageUrl)
    }
}
