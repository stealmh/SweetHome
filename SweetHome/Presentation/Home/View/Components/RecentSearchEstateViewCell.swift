//
//  RecentSearchEstateViewCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class RecentSearchEstateViewCell: UICollectionViewCell {
    static let identifier = "RecentSearchEstateViewCell"
    
    private let thumbnailImageView: UIImageView = {
        let v = UIImageView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        v.contentMode = .scaleToFill
        return v
    }()
    /// - 추천일 때 visible
    private let recommendTagView = SHTagView(text: "추천")
    /// - 건물 타입(원룸, 오피스텔 등)
    private let estateTypeLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.semiBold), size: .caption2)
        v.textColor = SHColor.Brand.deepWood
        return v
    }()
    
    // 제약 조건 참조 변수들
    private var estateTypeLabelLeadingConstraint: Constraint?
    /// - ex: 월세 3000/20
    private let rentPriceLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    /// - 문래동 112.4m^2
    private let locationAndSizeLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
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
        // Cell view styling
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = SHColor.GrayScale.gray_30.cgColor
        clipsToBounds = true
        
        contentView.addSubviews(
            thumbnailImageView,
            recommendTagView,
            estateTypeLabel,
            rentPriceLabel,
            locationAndSizeLabel
        )
    }
    
    private func setupConstraints() {
        thumbnailImageView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview().inset(10)
            $0.width.height.equalTo(68)
        }
        
        recommendTagView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
        }
        
        estateTypeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(15)
            estateTypeLabelLeadingConstraint = $0.leading.equalTo(recommendTagView.snp.trailing).offset(4).constraint
            $0.trailing.equalToSuperview().inset(10)
        }
        
        rentPriceLabel.snp.makeConstraints {
            $0.top.equalTo(recommendTagView.snp.bottom).offset(8)
            $0.leading.equalTo(recommendTagView)
            $0.trailing.equalToSuperview().inset(10)
        }
        
        locationAndSizeLabel.snp.makeConstraints {
            $0.leading.equalTo(recommendTagView)
            $0.top.equalTo(rentPriceLabel.snp.bottom).offset(8)
            $0.trailing.equalToSuperview().inset(10)
            $0.bottom.equalToSuperview().inset(14)
        }
    }
    
    func configure(with estate: Estate) {
        thumbnailImageView.setAuthenticatedImage(with: estate.thumbnails.first!)
        estateTypeLabel.text = estate.category
        rentPriceLabel.text = estate.rentDisplayText
        //TODO: 위치 정보 추가해서 넣기
        locationAndSizeLabel.text = "문래동 \(estate.area)m²"
        recommendTagView.isHidden = !estate.isRecommended
        
        // 추천 태그 표시 여부에 따라 estateTypeLabel 위치 조정
        estateTypeLabelLeadingConstraint?.deactivate()
        
        if estate.isRecommended {
            estateTypeLabel.snp.makeConstraints {
                estateTypeLabelLeadingConstraint = $0.leading.equalTo(recommendTagView.snp.trailing).offset(4).constraint
            }
        } else {
            estateTypeLabel.snp.makeConstraints {
                estateTypeLabelLeadingConstraint = $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12).constraint
            }
        }
    }
    
}
