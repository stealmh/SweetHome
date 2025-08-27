//
//  ChatNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import SnapKit

class ChatNavigationBar: UIView {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "채팅"
        v.setFont(.pretendard(.medium), size: .title1)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    let searchButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.search, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    let settingsButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.fire, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let buttonStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 8
        v.distribution = .equalSpacing
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

private extension ChatNavigationBar {
    func setupUI() {
        backgroundColor = .systemBackground
        addSubviews(titleLabel, buttonStackView)
        buttonStackView.addArrangeSubviews(searchButton, settingsButton)
    }
    
    func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(titleLabel)
        }
        
        searchButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
        
        settingsButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }
}
