//
//  EstateDetailBrokerCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailBrokerCell: UICollectionViewCell {
    static let identifier = "EstateDetailBrokerCell"
    
    private let profileImageView: UIImageView = {
        let v = UIImageView()
        return v
    }()
    
    private let brokerCompanyLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body1)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    
    private let brokerDescriptionLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.regular), size: .body3)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    private let brokerCallButton = EstateDetailBrokerButton()
    private let brokerChatButton = EstateDetailBrokerButton()
    
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
        brokerCallButton.configure(with: SHAsset.Icon.phone)
        brokerChatButton.configure(with: SHAsset.Icon.frame)
        contentView.addSubviews(profileImageView, brokerCompanyLabel, brokerDescriptionLabel, brokerCallButton, brokerChatButton)
    }
    
    func setupConstraints() {
        profileImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().inset(8)
            $0.leading.equalToSuperview()
            $0.width.height.equalTo(60)
        }
        
        brokerChatButton.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.top).offset(10)
            $0.bottom.equalTo(profileImageView.snp.bottom).inset(10)
            $0.trailing.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        
        brokerCallButton.snp.makeConstraints {
            $0.top.equalTo(brokerChatButton)
            $0.trailing.equalTo(brokerChatButton.snp.leading).offset(-8)
            $0.width.height.equalTo(40)
        }
        
        brokerCompanyLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.top).offset(9.5)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(brokerCallButton.snp.leading).offset(-12)
        }
        
        brokerDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(brokerCompanyLabel.snp.bottom).offset(6)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(brokerCallButton.snp.leading).offset(-12)
        }
    }
    
    // MARK: - Configure
    func configure(with creator: Creator) {
        brokerCompanyLabel.text = creator.nick
        brokerDescriptionLabel.text = creator.introduction
        
        // 프로필 이미지 설정
        if let profileImageUrl = creator.profileImage, !profileImageUrl.isEmpty {
            profileImageView.backgroundColor = SHColor.GrayScale.gray_15
            profileImageView.layer.cornerRadius = 30
            profileImageView.clipsToBounds = true
            profileImageView.setAuthenticatedImage(with: profileImageUrl)
        } else {
            // 기본 프로필 이미지
            profileImageView.backgroundColor = SHColor.GrayScale.gray_15
            profileImageView.layer.cornerRadius = 30
            profileImageView.clipsToBounds = true
        }
        
        // 버튼 액션 설정
        brokerCallButton.onTapped = {
            print("전화")
        }
        
        brokerChatButton.onTapped = {
            print("채팅")
        }
    }
}
