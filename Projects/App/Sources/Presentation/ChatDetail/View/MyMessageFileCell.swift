//
//  MyMessageFileCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/31/25.
//

import UIKit
import SnapKit

final class MyMessageFileCell: UICollectionViewCell {
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
        contentView.addSubviews(photoCollectionView, timeLabel)
        
        photoCollectionView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(4)
            $0.leading.greaterThanOrEqualToSuperview().inset(60)
        }
        
        timeLabel.snp.makeConstraints {
            $0.bottom.equalTo(photoCollectionView.snp.bottom)
            $0.trailing.equalTo(photoCollectionView.snp.leading).offset(-4)
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
        }
    }
    
    func configure(with message: LastChat, shouldShowTime: Bool = true) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.createdAt)
        timeLabel.isHidden = !shouldShowTime
        
        photoCollectionView.configure(with: message.attachedFiles)
    }
}
