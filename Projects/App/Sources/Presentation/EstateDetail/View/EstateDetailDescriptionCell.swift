//
//  EstateDetailDescriptionCell.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

class EstateDetailDescriptionCell: UICollectionViewCell {
    static let identifier = "EstateDetailDescriptionCell"
    
    private let descriptionLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.regular), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_60
        v.numberOfLines = 0
        v.lineBreakMode = .byWordWrapping
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
    
    func setupUI() {
        contentView.addSubview(descriptionLabel)
    }
    
    func setupConstraints() {
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(8)
            $0.leading.trailing.equalTo(contentView)
            $0.bottom.equalTo(contentView).inset(8)
        }
    }
    
    func configure(description: String) {
        descriptionLabel.text = description
    }
}
