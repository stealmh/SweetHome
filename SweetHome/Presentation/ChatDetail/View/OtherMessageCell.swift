//
//  OtherMessageCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

final class OtherMessageCell: UICollectionViewCell {
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
        view.backgroundColor = .systemGray6
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubviews(profileImageView, nameLabel, messageView, timeLabel)
        messageView.addSubview(messageLabel)
        
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
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.width.lessThanOrEqualTo(280)
        }
        
        messageLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        
        timeLabel.snp.makeConstraints {
            $0.bottom.equalTo(messageView.snp.bottom)
            $0.leading.equalTo(messageView.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
    }
    
    func configure(with message: LastChat, shouldShowTime: Bool = true, shouldShowProfile: Bool = true) {
        messageLabel.text = message.displayLabel
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        timeLabel.isHidden = !shouldShowTime
        
        if shouldShowProfile {
            nameLabel.text = message.sender.nickname
            profileImageView.setAuthenticatedImage(with: message.sender.profileImageURL, defaultImageType: .profile)
            profileImageView.isHidden = false
            nameLabel.isHidden = false
            
            messageView.snp.remakeConstraints {
                $0.top.equalTo(nameLabel.snp.bottom).offset(4)
                $0.bottom.equalToSuperview().inset(4)
                $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                $0.width.lessThanOrEqualTo(280)
            }
        } else {
            profileImageView.isHidden = true
            nameLabel.isHidden = true
            
            messageView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(4)
                $0.bottom.equalToSuperview().inset(4)
                $0.leading.equalToSuperview().inset(56)
                $0.width.lessThanOrEqualTo(280)
            }
        }
    }
}
