//
//  EmptyRecentSearchViewCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class EmptyRecentSearchViewCell: UICollectionViewCell {
    static let identifier = "EmptyRecentSearchViewCell"
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "최근 검색한 매물이 없어요"
        v.setFont(.pretendard(.medium), size: .body2)
        v.textColor = SHColor.GrayScale.gray_90
        v.textAlignment = .center
        return v
    }()
    
    private let subtitleLabel: UILabel = {
        let v = UILabel()
        v.text = "원하는 매물을 검색해보세요"
        v.setFont(.pretendard(.regular), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .center
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
        backgroundColor = .clear
        contentView.addSubviews(titleLabel, subtitleLabel)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = SHColor.GrayScale.gray_30.cgColor
        clipsToBounds = true
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
