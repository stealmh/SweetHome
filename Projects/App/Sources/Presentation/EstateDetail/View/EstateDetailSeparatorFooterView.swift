//
//  EstateDetailSeparatorFooterView.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

final class EstateDetailSeparatorFooterView: UICollectionReusableView {
    static let identifier = "EstateDetailSeparatorFooterView"
    
    // MARK: - UI Components
    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_30
        return v
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        addSubview(separatorLine)
    }
    
    private func setupConstraints() {
        separatorLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
