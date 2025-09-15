//
//  OtherMessageFileCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/31/25.
//

import UIKit
import SnapKit

final class OtherMessageFileCell: UICollectionViewCell {
    private let profileImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 20
        v.backgroundColor = .systemGray5
        return v
    }()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textColor = .label
        return v
    }()
    
    private let photoCollectionView = PhotoCollectionView()
    
    private let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = .systemGray
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubviews(profileImageView, nameLabel, photoCollectionView, timeLabel)
        
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
        
        photoCollectionView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().inset(4)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(60)
        }
        
        timeLabel.snp.makeConstraints {
            $0.bottom.equalTo(photoCollectionView.snp.bottom)
            $0.leading.equalTo(photoCollectionView.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
    }
    
    func configure(with message: LastChat, shouldShowTime: Bool = true, shouldShowProfile: Bool = true) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        timeLabel.isHidden = !shouldShowTime
        
        photoCollectionView.configure(with: message.attachedFiles)
        
        if shouldShowProfile {
            nameLabel.text = message.sender.nickname
            profileImageView.setAuthenticatedImage(with: message.sender.profileImageURL, defaultImageType: .profile)
            profileImageView.isHidden = false
            nameLabel.isHidden = false
        } else {
            profileImageView.isHidden = true
            nameLabel.isHidden = true
        }
    }
}
