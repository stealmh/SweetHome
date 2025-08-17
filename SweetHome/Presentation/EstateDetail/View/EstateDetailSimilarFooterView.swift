//
//  EstateDetailSimilarFooterView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailSimilarFooterView: UICollectionReusableView {
    static let identifier = "EstateDetailSimilarFooterView"
    
    private let iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.tintColor = SHColor.GrayScale.gray_45
        v.image = SHAsset.Icon.safety
        return v
    }()
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body3)
        v.textColor = SHColor.GrayScale.gray_45
        v.textAlignment = .left
        v.text = "AI 알고리즘 기반으로 추천된 매물입니다."
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
        addSubviews(iconImageView, titleLabel)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview()
        }
    }
}
