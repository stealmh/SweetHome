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
        layer.borderColor = SHColor.GrayScale.gray_60.cgColor
        layer.borderWidth = 1
        backgroundColor = .white
        layer.cornerRadius = 16
        
        addSubviews(parkingIcon, parkingLabel)
    }
    
    private func setupConstraints() {
        self.snp.makeConstraints {
            $0.height.equalTo(32)
        }
        
        parkingIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12.5)
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().inset(6)
            $0.width.height.equalTo(20)
        }
        
        parkingLabel.snp.makeConstraints {
            $0.leading.equalTo(parkingIcon.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(12.5)
            $0.top.equalToSuperview().offset(9)
            $0.bottom.equalToSuperview().inset(9)
        }
    }
    
    // MARK: - Public Methods
    func configure(parkingCount: Int) {
        let text = parkingCount == 0 ? "주차 불가" : "세대별 차량 \(parkingCount)대 주차 가능"
        parkingLabel.text = text
    }
}
