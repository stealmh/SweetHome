//
//  ChatRoomCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/18/25.
//

import UIKit
import SnapKit

class ChatRoomCell: UICollectionViewCell {
    private let profileImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = SHColor.GrayScale.gray_30.cgColor
        v.clipsToBounds = true
        v.tintColor = .black
        return v
    }()
    
    private let userNameLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body1)
        return v
    }()
    
    private let pinImageView: UIImageView = {
        let v = UIImageView()
        return v
    }()
    
    private let messageLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body2)
        v.textColor = SHColor.GrayScale.gray_60
        v.numberOfLines = 2
        return v
    }()
    
    private let dateLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body3)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .right
        return v
    }()
    
    private let messageCountContainerView = UIView()
    
    private let messageCountLabel: UILabel = {
        let v = UILabel()
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

private extension ChatRoomCell {
    func setupUI() {
        addSubviews(profileImageView, userNameLabel, messageLabel, pinImageView, dateLabel)
    }
    
    func setupConstraints() {
        profileImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.height.equalTo(56)
        }
        
        userNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
        }
        
        pinImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(userNameLabel.snp.trailing).offset(8)
            $0.width.height.equalTo(10)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.bottom.equalTo(profileImageView)
            $0.trailing.equalToSuperview()
            $0.width.greaterThanOrEqualTo(40)
        }
        
        messageLabel.snp.makeConstraints {
            $0.top.equalTo(userNameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(userNameLabel)
            $0.trailing.equalTo(dateLabel.snp.leading).offset(-8)
        }
    }
}

extension ChatRoomCell {
    func configure(with chatRoom: ChatRoom) {
        userNameLabel.text = chatRoom.participants.first?.nickname
        messageLabel.text = chatRoom.lastChat.content
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        dateLabel.text = formatter.string(from: chatRoom.lastChat.createdAt)
        profileImageView.setAuthenticatedImage(with: chatRoom.participants[0].profileImageURL)
    }
}
