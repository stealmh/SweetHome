//
//  EstateTopicViewCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class EstateTopicViewCell: UICollectionViewCell {
    static let identifier = "EstateTopicViewCell"
    
    private let topicTitleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body2)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    
    private let contentLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.regular), size: .body2)
        v.textColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    private let dateLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.regular), size: .body2)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let divideView: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_15
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
    
    private func setupUI() {
        addSubviews(topicTitleLabel, contentLabel, dateLabel, divideView)
    }
    
    private func setupConstraints() {
        topicTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview()
        }
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(topicTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(topicTitleLabel)
            $0.trailing.equalToSuperview().inset(54)
        }
        dateLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        
        divideView.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(12 + 5)
            $0.height.equalTo(1)
            $0.leading.trailing.equalToSuperview()
        }
    }
    
    func configure(_ data: EstateTopic) {
        topicTitleLabel.text = data.title
        contentLabel.text = data.content
        dateLabel.text = data.date
    }
}
