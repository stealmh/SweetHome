//
//  EstateMapFilterButton.swift
//  SweetHome
//
//  Created by 김민호 on 8/7/25.
//

import UIKit

/// - 지도화면 필터링을 위한 캡슐형 버튼
class EstateMapFilterButton: UIButton {
    
    // MARK: - Properties
    /// - 버튼 탭 시 실행될 클로저
    var buttonTapped: (() -> Void)?
    
    /// - 버튼 선택 상태
    override var isSelected: Bool {
        didSet {
            updateConfigurationAppearance()
        }
    }
    
    /// - 버튼 활성화 상태
    override var isEnabled: Bool {
        didSet {
            updateConfigurationAppearance()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    private func setupButton() {
        setupAppearance()
        updateConfigurationAppearance()
        
        /// - 터치 이벤트 추가
        addTarget(self, action: #selector(buttonTappedAction), for: .touchUpInside)
    }
    
    private func setupAppearance() {
        /// - iOS 15 이상에서는 UIButton.Configuration 사용
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            
            /// - 내용 여백 설정 (top: 7.5, leading: 13, bottom: 7.5, trailing: 13)
            config.contentInsets = NSDirectionalEdgeInsets(top: 7.5, leading: 13, bottom: 7.5, trailing: 13)
            
            /// - 기본 폰트 설정
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = SHFont.pretendard(.medium).setSHFont(.body2)
                return outgoing
            }
            
            /// - 배경 색상은 updateAppearance에서 설정
            config.background.backgroundColor = .white
            
            self.configuration = config
        } else {
            /// - iOS 15 미만에서는 기존 방식 사용
            titleLabel?.font = SHFont.pretendard(.medium).setSHFont(.body2)
            contentEdgeInsets = UIEdgeInsets(top: 7.5, left: 13, bottom: 7.5, right: 13)
        }
        
        /// - 레이어 설정
        layer.borderWidth = 1
        clipsToBounds = true
        
        /// - 텍스트 크기에 따라 너비 자동 조정
        sizeToFit()
    }
    
    private func updateConfigurationAppearance() {
        if #available(iOS 15.0, *) {
            guard var config = configuration else { return }
            
            if !isEnabled {
                /// - 비활성화 상태
                config.baseForegroundColor = SHColor.GrayScale.gray_75
                layer.borderColor = SHColor.GrayScale.gray_45.cgColor
            } else if isSelected {
                /// - 선택된 상태
                config.baseForegroundColor = SHColor.Brand.brightWood
                layer.borderColor = SHColor.Brand.brightWood.cgColor
            } else {
                /// - 기본 상태
                config.baseForegroundColor = SHColor.GrayScale.gray_75
                layer.borderColor = SHColor.GrayScale.gray_45.cgColor
            }
            
            self.configuration = config
        } else {
            /// - iOS 15 미만에서는 기존 방식 사용
            if !isEnabled {
                setTitleColor(SHColor.GrayScale.gray_75, for: .normal)
                layer.borderColor = SHColor.GrayScale.gray_45.cgColor
            } else if isSelected {
                setTitleColor(SHColor.Brand.brightWood, for: .normal)
                layer.borderColor = SHColor.Brand.brightWood.cgColor
            } else {
                setTitleColor(SHColor.GrayScale.gray_75, for: .normal)
                layer.borderColor = SHColor.GrayScale.gray_45.cgColor
            }
        }
    }
    
    /// - 레이아웃 업데이트 시 코너 반지름 설정 (캡슐 형태)
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
    
    // MARK: - Actions
    @objc private func buttonTappedAction() {
        /// - 버튼 탭 시 선택 상태 토글
        isSelected.toggle()
        
        /// - 클로저 실행
        buttonTapped?()
    }
    
    // MARK: - Public Methods
    /// - 버튼 텍스트 설정
    func configure(title: String) {
        if #available(iOS 15.0, *) {
            guard var config = configuration else { return }
            config.title = title
            self.configuration = config
        } else {
            setTitle(title, for: .normal)
        }
        
        /// - 외관 업데이트
        updateConfigurationAppearance()
        
        /// - 텍스트 변경 후 크기 재조정
        sizeToFit()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    /// - 선택 상태 설정
    func setSelected(_ selected: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.isSelected = selected
            }
        } else {
            isSelected = selected
        }
    }
}
