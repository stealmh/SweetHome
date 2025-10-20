//
//  EstateDetailBannerFooterView.swift
//  SweetHome
//
//  Created by 김민호 on 8/15/25.
//

import UIKit
import SnapKit

class EstateDetailBannerFooterView: UICollectionReusableView {
    static let identifier = "EstateDetailBannerFooterView"
    
    private let countLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .left
        return v
    }()
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body3)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .left
        v.text = "명이 함께 보는 중"
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        backgroundColor = UIColor(hex: "#E9E5E2").withAlphaComponent(0.5)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        addSubviews(countLabel, titleLabel)
    }
    
    private func setupConstraints() {
        countLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(countLabel.snp.trailing)
            $0.centerY.equalToSuperview()
        }
    }
    
    func configure(with count: Int) {
        countLabel.text = count == 0 ? "1" : "\(count)"
    }
}
