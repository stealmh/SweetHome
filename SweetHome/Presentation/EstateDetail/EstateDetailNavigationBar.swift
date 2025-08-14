//
//  EstateDetailNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import UIKit
import SnapKit

class EstateDetailNavigationBar: UIView {
    // MARK: - UI Components
    let backButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.chevron, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let estateNameLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body1)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    let favoriteButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.list, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
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
}

private extension EstateDetailNavigationBar {
    func setupUI() {
        addSubviews(estateNameLabel, backButton, favoriteButton)
    }
    
    func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        
        estateNameLabel.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(4)
            $0.centerY.equalTo(backButton)
        }
        
        favoriteButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
}

extension EstateDetailNavigationBar {
    func configure(_ item: DetailEstate) {
        /// - 타이틀 업데이트
        estateNameLabel.text = item.title
        /// - 좋아요 버튼 상태 업데이트
        let likeImage = item.isLiked ? SHAsset.Icon.likeFill : SHAsset.Icon.likeEmpty
        favoriteButton.setImage(likeImage, for: .normal)
    }
}
