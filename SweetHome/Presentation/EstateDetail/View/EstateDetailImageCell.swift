//
//  EstateDetailImageCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit
import SnapKit

class EstateDetailImageCell: UICollectionViewCell {
    static let identifier = "EstateDetailImageCell"
    
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
        /// - 인증된 이미지 로드 (매물 상세 이미지)
        imageView.setAuthenticatedImage(with: imageUrl)
    }
}