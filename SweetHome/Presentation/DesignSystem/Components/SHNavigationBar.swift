//
//  SHNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

class SHNavigationBar: UIView {
    // MARK: - UI Components
    let backButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.chevron, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body1)
        v.textColor = SHColor.GrayScale.gray_100
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
}

private extension SHNavigationBar {
    func setupUI() {
        addSubviews(titleLabel, backButton)
    }
    
    func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }
    }
}

extension SHNavigationBar {
    func configure(title: String) {
        titleLabel.text = title
    }
}
