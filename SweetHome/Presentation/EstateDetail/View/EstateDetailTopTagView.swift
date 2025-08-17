//
//  EstateDetailTopTagView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailTopTagView: UIView {
    private let locationIcon: UIImageView = {
        let v = UIImageView()
        v.image = SHAsset.Icon.safety
        v.tintColor = SHColor.Brand.deepCoast
        v.contentMode = .scaleToFill
        return v
    }()
    
    private let locationLabel: UILabel = {
        let v = UILabel()
        v.font = SHFont.pretendard(.semiBold).setSHFont(.caption1)
        v.textColor = SHColor.Brand.deepCoast
        v.textAlignment = .left
        v.text = "구매자 안심매물"
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
        layer.borderColor = SHColor.Brand.deepCoast.cgColor
        layer.borderWidth = 1
        backgroundColor = .white
        layer.cornerRadius = 14
        
        addSubviews(locationIcon, locationLabel)
    }
    
    private func setupConstraints() {
        self.snp.makeConstraints {
            $0.height.equalTo(24)
        }
        
        locationIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.top.equalToSuperview().offset(4)
            $0.bottom.equalToSuperview().inset(4)
            $0.width.height.equalTo(16)
        }
        
        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationIcon.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(10)
            $0.top.equalToSuperview().offset(5)
            $0.bottom.equalToSuperview().inset(5)
        }
    }
}
