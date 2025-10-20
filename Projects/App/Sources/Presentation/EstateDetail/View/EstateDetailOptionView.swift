//
//  EstateDetailOptionView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailOptionView: UIView {
    private let optionImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        return v
    }()
    
    private let optionNameLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.semiBold), size: .caption1)
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
        addSubviews(optionImageView, optionNameLabel)
    }
    
    func setupConstraints() {
        optionImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        
        optionNameLabel.snp.makeConstraints {
            $0.top.equalTo(optionImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
    }
    
    func configure(optionImage: UIImage?, optionName: String, hasOption: Bool) {
        optionImageView.image = optionImage
        optionNameLabel.text = optionName
        
        if hasOption {
            optionImageView.tintColor = SHColor.GrayScale.gray_75
            optionNameLabel.textColor = SHColor.GrayScale.gray_75
        } else {
            optionImageView.tintColor = SHColor.GrayScale.gray_30
            optionNameLabel.textColor = SHColor.GrayScale.gray_30
        }
        
    }
}
