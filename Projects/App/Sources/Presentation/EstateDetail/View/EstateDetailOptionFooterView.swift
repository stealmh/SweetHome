//
//  EstateDetailOptionFooterView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailOptionFooterView: UICollectionReusableView {
    static let identifier = "EstateDetailOptionFooterView"
    
    private let parkingContainer = UIView()
    
    private let parkingIcon: UIImageView = {
        let v = UIImageView()
        v.image = SHAsset.Option.parking
        v.tintColor = SHColor.GrayScale.gray_60
        v.contentMode = .scaleToFill
        return v
    }()
    
    private let parkingLabel: UILabel = {
        let v = UILabel()
        v.font = SHFont.pretendard(.semiBold).setSHFont(.caption1)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .left
        return v
    }()
    
    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_30
        return v
    }()
    
    // MARK: - Initialization
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
    
    // MARK: - Setup Methods
    private func setupUI() {
        addSubviews(parkingContainer, separatorLine)
        parkingContainer.addSubviews(parkingIcon, parkingLabel)
        
        // 컨테이너 스타일 설정
        parkingContainer.layer.borderColor = SHColor.GrayScale.gray_60.cgColor
        parkingContainer.layer.borderWidth = 1
        parkingContainer.backgroundColor = .white
        parkingContainer.layer.cornerRadius = 16
    }
    
    private func setupConstraints() {
        // 컨테이너는 컨텐츠 크기에 맞춤
        parkingContainer.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.height.equalTo(32)
        }
        
        parkingIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12.5)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        parkingLabel.snp.makeConstraints {
            $0.leading.equalTo(parkingIcon.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(12.5)
            $0.centerY.equalToSuperview()
        }
        
        // separator는 컨테이너와 16의 간격, 상하 5의 간격
        separatorLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(parkingContainer.snp.bottom).offset(16)
            $0.bottom.equalToSuperview().inset(5)
            $0.height.equalTo(1)
        }
    }
    
    // MARK: - Public Methods
    func configure(parkingCount: Int) {
        let text = parkingCount == 0 ? "주차 불가" : "세대별 차량 \(parkingCount)대 주차 가능"
        parkingLabel.text = text
    }
}
