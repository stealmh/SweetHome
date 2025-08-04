//
//  EstateTypeButton.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit

class EstateTypeButton: UIView {
    private let bannerType: BannerEstateType
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = SHColor.GrayScale.gray_30
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        return v
    }()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .body3)
        v.textColor = SHColor.GrayScale.gray_75
        v.textAlignment = .center
        return v
    }()
    
    private var tapGesture: UITapGestureRecognizer!
    var onTapped: (() -> Void)?
    
    init(type: BannerEstateType) {
        self.bannerType = type
        super.init(frame: .zero)
        setupUI()
        configure()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        addSubview(titleLabel)
        containerView.addSubview(iconImageView)
        
        containerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(containerView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    private func configure() {
        iconImageView.image = UIImage(named: bannerType.imageName)
        titleLabel.text = bannerType.title
    }
    
    private func setupTapGesture() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func viewTapped() {
        onTapped?()
    }
}
