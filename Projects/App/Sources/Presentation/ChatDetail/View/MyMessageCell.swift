//
//  MyMessageCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

final class MyMessageCell: UICollectionViewCell {
    private let messageView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.backgroundColor = .systemBlue
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
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
        contentView.addSubviews(messageView, timeLabel)
        messageView.addSubview(messageLabel)
        
        messageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(4)
            $0.width.lessThanOrEqualTo(280)
            $0.leading.greaterThanOrEqualToSuperview().inset(60)
        }
        
        messageLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        
        timeLabel.snp.makeConstraints {
            $0.bottom.equalTo(messageView.snp.bottom)
            $0.trailing.equalTo(messageView.snp.leading).offset(-4)
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
        }
    }
    
    func configure(with message: LastChat, shouldShowTime: Bool = true) {
        messageLabel.text = message.displayLabel
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        timeLabel.isHidden = !shouldShowTime
    }
}
