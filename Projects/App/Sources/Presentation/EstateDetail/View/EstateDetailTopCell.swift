//
//  EstateDetailTopCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailTopCell: UICollectionViewCell {
    static let identifier = "EstateDetailTopCell"
    
    private let topTagView = EstateDetailTopTagView()

    private let agoLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body3)
        v.textColor = SHColor.GrayScale.gray_45
        return v
    }()
    
    private let locationLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body2)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    /// - 월세 or 전세 구분
    private let locationRentTypeLabel: UILabel = {
        let v = UILabel()
        v.setFont(.yeongdeok, size: .title1)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let locationRentLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: ._30)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    
    private let locationFeeAreaLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body2)
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
    
    func setupUI() {
        contentView.addSubviews(topTagView, agoLabel, locationLabel, locationRentTypeLabel, locationRentLabel, locationFeeAreaLabel)
    }
    
    func setupConstraints() {
        topTagView.snp.makeConstraints {
            $0.top.equalTo(contentView)
            $0.leading.equalTo(contentView)
        }
        
        agoLabel.snp.makeConstraints {
            $0.top.equalTo(topTagView).offset(4)
            $0.trailing.equalTo(contentView)
        }
        
        locationLabel.snp.makeConstraints {
            $0.top.equalTo(topTagView.snp.bottom).offset(16)
            $0.leading.equalTo(topTagView)
            $0.trailing.equalTo(agoLabel)
        }
        
        locationRentTypeLabel.snp.makeConstraints {
            $0.top.equalTo(locationLabel.snp.bottom).offset(4 + 3)
            $0.leading.equalTo(locationLabel)
            $0.bottom.equalTo(locationRentLabel)
        }
        
        locationRentLabel.snp.makeConstraints {
            $0.top.equalTo(locationLabel.snp.bottom).offset(4)
            $0.leading.equalTo(locationRentTypeLabel.snp.trailing).offset(8)
        }
        
        locationFeeAreaLabel.snp.makeConstraints {
            $0.top.equalTo(locationRentLabel.snp.bottom).offset(4)
            $0.leading.equalTo(locationLabel)
        }
    }
    
    func configure(_ item: DetailEstate) {
        agoLabel.text = item.daysAgoText
        locationLabel.text = "서울 영등포구 선유로 9길 30"
        locationRentTypeLabel.text = item.rentTypeText
        locationRentLabel.text = item.rentDisplayText
        locationFeeAreaLabel.text = "관리비 \(item.formattedMaintenanceFee) • \(item.locationAndAreaText)"
    }
}
