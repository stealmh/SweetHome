//
//  ChatMessageCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

final class ChatMessageCell: UICollectionViewCell {
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let messageView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let senderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray2
        return label
    }()
    
    private var isMyMessage = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubviews(profileImageView, nameLabel, messageView)
        messageView.addSubviews(messageLabel, timeLabel)
        
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(40)
            $0.leading.equalToSuperview().inset(8)
            $0.top.equalTo(nameLabel.snp.top)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        
        messageView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().inset(4)
            $0.width.lessThanOrEqualTo(280)
        }
        
        messageLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
        }
        
        timeLabel.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }
    
    func configure(with message: LastChat) {
        let currentUserId = KeyChainManager.shared.read(.userID) ?? ""
        isMyMessage = message.sender.userId == currentUserId
        
        messageLabel.text = message.content
        
        // 프로필 이미지와 이름 설정 (상대방 메시지일 때만)
        if !isMyMessage {
            nameLabel.text = message.sender.nickname
            profileImageView.setAuthenticatedImage(with: message.sender.profileImageURL, defaultImageType: .profile)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        
        updateLayout()
    }
    
    private func updateLayout() {
        if isMyMessage {
            // 내 메시지일 때는 프로필 이미지와 이름 숨김
            profileImageView.isHidden = true
            nameLabel.isHidden = true
            
            messageView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            timeLabel.textColor = .white.withAlphaComponent(0.7)
            
            messageView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview().inset(4)
                $0.trailing.equalToSuperview().inset(8)
                $0.width.lessThanOrEqualTo(280)
            }
        } else {
            // 상대방 메시지일 때는 프로필 이미지와 이름 표시
            profileImageView.isHidden = false
            nameLabel.isHidden = false
            
            messageView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            timeLabel.textColor = .systemGray
            
            messageView.snp.remakeConstraints {
                $0.top.equalTo(nameLabel.snp.bottom).offset(4)
                $0.bottom.equalToSuperview().inset(4)
                $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                $0.width.lessThanOrEqualTo(280)
            }
        }
    }
}
