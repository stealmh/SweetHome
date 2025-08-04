//
//  HotEstateViewCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class HotEstateViewCell: UICollectionViewCell {
    static let identifier = "HotEstateViewCell"
    
    private let backgroundImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        return v
    }()
    /// - 불 아이콘
    private let hotImageView: UIImageView = {
        let v = UIImageView()
        v.image = SHAsset.Icon.fire
        v.tintColor = SHColor.GrayScale.gray_0
        return v
    }()
    /// - n명이 함께 보는중
    private let watchTagView = SHTagView()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .right
        v.setFont(.yeongdeok, size: .caption1)
        v.textColor = SHColor.GrayScale.gray_0
        return v
    }()
    
    /// - ex: 월세 3000/20
    private let rentPriceLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_0
        v.textAlignment = .right
        return v
    }()
    /// - 문래동 112.4m^2
    private let locationAndSizeLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption2)
        v.textColor = SHColor.GrayScale.gray_45
        v.textAlignment = .right
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
        layer.cornerRadius = 12
        clipsToBounds = true
        
        contentView.addSubviews(
            backgroundImageView,
            hotImageView,
            watchTagView,
            titleLabel,
            rentPriceLabel,
            locationAndSizeLabel
        )
    }
    
    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        hotImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(10)
            $0.width.height.equalTo(24)
        }
        
        watchTagView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().offset(10)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().inset(11)
            $0.leading.equalTo(hotImageView.snp.trailing).offset(10)
        }
        
        rentPriceLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(1)
            $0.trailing.equalTo(titleLabel)
        }
        
        locationAndSizeLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(9)
            $0.trailing.equalToSuperview().inset(11)
            $0.leading.equalTo(watchTagView.snp.trailing).offset(10)
        }
    }
    
    func configure(with estate: Estate) {
        backgroundImageView.setAuthenticatedImage(with: estate.thumbnails.first ?? "")
        titleLabel.text = estate.title
        rentPriceLabel.text = estate.rentDisplayText
        locationAndSizeLabel.text = "\(estate.area)m²" // TODO: 위치 정보 추가
        
        // 랜덤한 시청자 수 (1-10명)
        let watchCount = Int.random(in: 1...10)
        watchTagView.configure(
            text: "\(watchCount)명이 함께 보는중",
            backgroundColor: SHColor.GrayScale.gray_90.withAlphaComponent(0.7),
            textColor: SHColor.GrayScale.gray_0
        )
    }
}
