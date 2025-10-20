//
//  SHLocationTagView.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit

class SHLocationTagView: UIView {
    private let locationIcon: UIImageView = {
        let v = UIImageView()
        v.image = SHAsset.Icon.location
        v.tintColor = SHColor.GrayScale.gray_15
        v.contentMode = .scaleToFill
        return v
    }()
    
    private let locationLabel: UILabel = {
        let v = UILabel()
        v.font = SHFont.pretendard(.medium).setSHFont(.caption2)
        v.textColor = SHColor.GrayScale.gray_15
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
        backgroundColor = SHColor.GrayScale.gray_60.withAlphaComponent(0.5)
        layer.cornerRadius = 10
        
        addSubviews(locationIcon, locationLabel)
    }
    
    private func setupConstraints() {
        self.snp.makeConstraints {
            $0.height.equalTo(20)
        }
        
        locationIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.top.equalToSuperview().offset(2)
            $0.bottom.equalToSuperview().inset(2)
            $0.width.height.equalTo(16)
        }
        
        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationIcon.snp.trailing).offset(2)
            $0.trailing.equalToSuperview().inset(8)
            $0.top.equalToSuperview().offset(4)
            $0.bottom.equalToSuperview().inset(4)
        }
    }
    
    func setLabel(location: String) {
        locationLabel.text = location
    }
}
