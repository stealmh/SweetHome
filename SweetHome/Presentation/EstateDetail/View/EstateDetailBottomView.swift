//
//  EstateDetailBottomView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailBottomView: UIView {
    let favoriteButton: UIButton = {
        let v = UIButton()
        v.tintColor = SHColor.GrayScale.gray_60
        v.setImage(SHAsset.Icon.likeEmpty, for: .normal)
        return v
    }()
    
    let reservationButton: UIButton = {
        let v = UIButton()
        v.setTitle("예약하기", for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = SHColor.Brand.deepCream
        v.setTitleFont(.pretendard(.bold), size: .title1)
        v.layer.cornerRadius = 8
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
        addSubviews(favoriteButton, reservationButton)
    }
    
    private func setupConstraints() {
        favoriteButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalTo(28)
        }
        
        reservationButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.leading.equalTo(favoriteButton.snp.trailing).offset(23)
            $0.height.equalTo(48)
        }
    }
    
    func configure(_ isLiked: Bool) {
        /// - 좋아요 버튼 상태 업데이트
        let likeImage = isLiked ? SHAsset.Icon.likeFill : SHAsset.Icon.likeEmpty
        favoriteButton.setImage(likeImage, for: .normal)
    }
}
