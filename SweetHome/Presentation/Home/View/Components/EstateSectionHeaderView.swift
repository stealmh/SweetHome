//
//  EstateSectionHeaderView.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class EstateSectionHeaderView: UICollectionReusableView {
    
    // MARK: - Properties
    var onViewAllTapped: (() -> Void)?
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.bold), size: .body2)
        v.textColor = SHColor.GrayScale.gray_90
        return v
    }()
    
    private let viewAllButton: UIButton = {
        let v = UIButton()
        v.setTitle("View All", for: .normal)
        v.setTitleFont(.pretendard(.semiBold), size: .caption1)
        v.setTitleColor(SHColor.Brand.deepCoast, for: .normal)
        v.contentHorizontalAlignment = .trailing
        return v
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        addSubviews(titleLabel, viewAllButton)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(7.5)
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(viewAllButton.snp.leading).inset(20)
            $0.bottom.equalToSuperview().inset(7.5)
        }
        
        viewAllButton.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(9)
            $0.bottom.equalToSuperview().inset(9)
        }
    }
    
    private func setupActions() {
        viewAllButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func viewAllButtonTapped() {
        onViewAllTapped?()
    }
    
    // MARK: - Public Methods
    func configure(title: String, onViewAllTapped: @escaping () -> Void) {
        titleLabel.text = title
        self.onViewAllTapped = onViewAllTapped
        viewAllButton.isHidden = false
    }
    
    func configure(title: String, hideViewAll: Bool = false) {
        titleLabel.text = title
        self.onViewAllTapped = nil
        viewAllButton.isHidden = hideViewAll
    }
}
