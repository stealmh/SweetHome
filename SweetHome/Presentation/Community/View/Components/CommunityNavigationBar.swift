//
//  CommunityNavigationBar.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import UIKit
import SnapKit

/// - 커뮤니티 화면용 커스텀 네비게이션 바
class CommunityNavigationBar: UIView {

    /// - 콜백
    var onSearchTapped: (() -> Void)?
    var onNotificationTapped: (() -> Void)?

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SweetHome"
        label.font = SHFont.pretendard(.bold).setSHFont(.title1)
        label.textColor = .black
        return label
    }()

    private lazy var searchButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: config), for: .normal)
        button.tintColor = SHColor.GrayScale.gray_60
        button.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var notificationButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "bell.fill", withConfiguration: config), for: .normal)
        button.tintColor = SHColor.GrayScale.gray_60
        button.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        return button
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods
private extension CommunityNavigationBar {
    func setupUI() {
        backgroundColor = .white
        buttonStackView.addArrangeSubviews(searchButton, notificationButton)
        addSubviews(titleLabel, buttonStackView)
    }

    func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }

        buttonStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(84)
            $0.height.equalTo(44)
        }

        searchButton.snp.makeConstraints {
            $0.width.height.equalTo(30)
        }

        notificationButton.snp.makeConstraints {
            $0.width.height.equalTo(30)
        }
    }
}

// MARK: - Actions
private extension CommunityNavigationBar {
    @objc func searchButtonTapped() {
        onSearchTapped?()
    }

    @objc func notificationButtonTapped() {
        onNotificationTapped?()
    }
}
