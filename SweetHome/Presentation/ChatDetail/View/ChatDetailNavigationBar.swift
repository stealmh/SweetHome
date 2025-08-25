//
//  ChatDetailNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

class ChatDetailNavigationBar: UIView {
    // MARK: - UI Components
    let backButton: UIButton = {
        let v = UIButton()
        v.setImage(SHAsset.Icon.chevron, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let userNameLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body1)
        v.textColor = SHColor.GrayScale.gray_100
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

private extension ChatDetailNavigationBar {
    func setupUI() {
        addSubviews(userNameLabel, backButton)
    }
    
    func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
        
        userNameLabel.snp.makeConstraints {
            $0.top.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }
    }
}

extension ChatDetailNavigationBar {
    func configure(_ item: ChatSender) {
        /// - 타이틀 업데이트
        userNameLabel.text = item.nickname
    }
}
