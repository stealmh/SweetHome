//
//  EstateMapBottomCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/13/25.
//

import UIKit
import SnapKit

class EstateMapBottomCell: UICollectionViewCell {
    static let identifier = "EstateMapBottomCell"
    
    private let estateThumbnailView: UIImageView = {
        let v = UIImageView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        return v
    }()
    
    private let estateCateogryTagView = SHTagView()
    
    private let estateNameLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body3)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    /// - 전,월세 + 가격
    private let estatePriceInfoLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .title1)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    /// - 면적과 층
    private let estateAreaFloorLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    private let estateLocationLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 16
        setUI()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setUI() {
        backgroundColor = .white
        addSubviews(
            estateThumbnailView,
            estateCateogryTagView,
            estateNameLabel,
            estatePriceInfoLabel,
            estateAreaFloorLabel,
            estateLocationLabel
        )
    }
    
    func setConstraints() {
        estateThumbnailView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.width.height.equalTo(100)
            $0.bottom.equalToSuperview().inset(16)
        }
        
        estateCateogryTagView.snp.makeConstraints {
            $0.top.equalTo(estateThumbnailView).offset(7 + 1)
            $0.leading.equalTo(estateThumbnailView.snp.trailing).offset(20)
        }
        
        estateNameLabel.snp.makeConstraints {
            $0.top.equalTo(estateCateogryTagView.snp.top)
            $0.leading.equalTo(estateCateogryTagView.snp.trailing).offset(4)
        }
        
        estatePriceInfoLabel.snp.makeConstraints {
            $0.top.equalTo(estateCateogryTagView.snp.bottom).offset(6)
            $0.leading.equalTo(estateCateogryTagView)
        }
        
        estateAreaFloorLabel.snp.makeConstraints {
            $0.top.equalTo(estatePriceInfoLabel.snp.bottom).offset(6)
            $0.leading.equalTo(estateCateogryTagView)
        }
        
        estateLocationLabel.snp.makeConstraints {
            $0.top.equalTo(estateAreaFloorLabel.snp.bottom).offset(6)
            $0.leading.equalTo(estateCateogryTagView)
        }
    }
    
    func configure(type: BannerEstateType, _ item: EstateGeoLocationDataResponse) {
        estateThumbnailView.setAuthenticatedImage(with: item.thumbnails.first)
        estateCateogryTagView.configure(text: item.category, backgroundColor: SHColor.Brand.brightWood, textColor: .white)
        estateNameLabel.text = item.title
        // 가격 포맷팅 적용
        let formattedDeposit = item.deposit.formattedPrice
        let formattedMonthlyRent = item.monthly_rent.formattedPrice
        estatePriceInfoLabel.text = "\(type.rawValue) \(formattedDeposit)/\(formattedMonthlyRent)"
        
        estateAreaFloorLabel.text = "\(item.area)m² • \(item.floors)층"
        //TODO: 경도, 위도를 통한 도로명 주소 반환
        estateLocationLabel.text = "서울시 다람쥐로 12길"
    }
}
