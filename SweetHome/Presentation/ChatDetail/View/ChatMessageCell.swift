//
//  ChatMessageCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

final class ChatMessageCell: UICollectionViewCell {
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
        contentView.addSubview(messageView)
        messageView.addSubviews(senderLabel, messageLabel, timeLabel)
        
        messageView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.width.lessThanOrEqualTo(280)
        }
        
        senderLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
        }
        
        messageLabel.snp.makeConstraints {
            $0.top.equalTo(senderLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
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
        
        /// - 내가 보낸 메시지 이름 미표시
        if isMyMessage {
            senderLabel.text = ""
            senderLabel.isHidden = true
        } else {
            senderLabel.text = message.sender.nickname
            senderLabel.isHidden = false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        
        updateLayout()
    }
    
    private func updateLayout() {
        if isMyMessage {
            messageView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            senderLabel.textColor = .white.withAlphaComponent(0.8)
            timeLabel.textColor = .white.withAlphaComponent(0.7)
            
            messageLabel.snp.remakeConstraints {
                $0.top.leading.trailing.equalToSuperview().inset(12)
            }
            
            messageView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview().inset(4)
                $0.trailing.equalToSuperview().inset(8)
                $0.width.lessThanOrEqualTo(280)
            }
        } else {
            messageView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            senderLabel.textColor = .systemGray2
            timeLabel.textColor = .systemGray
            
            messageLabel.snp.remakeConstraints {
                $0.top.equalTo(senderLabel.snp.bottom).offset(4)
                $0.leading.trailing.equalToSuperview().inset(12)
            }
            
            messageView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview().inset(4)
                $0.leading.equalToSuperview().inset(8)
                $0.width.lessThanOrEqualTo(280)
            }
        }
    }
}
