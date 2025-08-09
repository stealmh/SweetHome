//
//  EstateMapNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/6/25.
//

import UIKit
import SnapKit

class EstateMapNavigationBar: UIView {
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.chevron, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let locationIconImageView: UIImageView = {
        let v = UIImageView()
        v.image = SHAsset.Icon.location
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let locationLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body1)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let menuButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.list, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    var backButtonTapped: (() -> Void)?
    var menuButtonTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setButtonAction()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setButtonAction()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        addSubviews(locationIconImageView, locationLabel, backButton, menuButton)
        //TODO: Mock
        locationLabel.text = "문래역, 영등포구"
    }
    
    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        
        locationIconImageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(12)
        }
        
        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationIconImageView.snp.trailing).offset(4)
            $0.centerY.equalTo(backButton)
        }
        
        menuButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
    
    private func setButtonAction() {
        backButton.addTarget(self, action: #selector(_backButtonTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(_menuButtonTapped), for: .touchUpInside)
    }
    
    @objc func _backButtonTapped() {
        backButtonTapped?()
    }
    
    @objc func _menuButtonTapped() {
        menuButtonTapped?()
    }
    
    func configure(_ locationName: String) {
        locationLabel.text = locationName
    }
}
