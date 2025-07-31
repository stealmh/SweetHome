//
//  SHInputFieldView.swift
//  SweetHome
//
//  Created by 김민호 on 7/30/25.
//

import UIKit
import SnapKit

class SHInputFieldView: UIView {
    
    // MARK: - UI Components
    private let placeholderStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 2
        v.alignment = .center
        return v
    }()
    
    private let placeholderLabel: UILabel = {
        let v = UILabel()
        v.textColor = SHColor.Brand.deepCoast
        v.setFont(.pretendard(.regular), size: .caption1)
        v.textColor = SHColor.GrayScale.gray_75
        return v
    }()
    
    private let requiredMarkLabel: UILabel = {
        let v = UILabel()
        v.text = "*"
        v.textColor = .red
        v.setFont(.pretendard(.regular), size: .caption1)
        v.isHidden = true
        return v
    }()
    
    private let textField: UITextField = {
        let v = UITextField()
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        v.leftViewMode = .always
        v.setFont(.pretendard(.regular), size: .body1)
        return v
    }()
    
    private let rightButton: UIButton = {
        let v = UIButton()
        v.isHidden = true
        v.tintColor = SHColor.GrayScale.gray_90
        return v
    }()
    
    private let validationMessageLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.regular), size: .caption2)
        v.textAlignment = .right
        v.isHidden = true
        return v
    }()
    
    // MARK: - Properties
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    var placeholderText: String? {
        get { placeholderLabel.text }
        set { placeholderLabel.text = newValue }
    }
    
    var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { 
            textField.isSecureTextEntry = newValue
            if !rightButton.isHidden {
                let imageName = newValue ? "eye.slash" : "eye"
                rightButton.setImage(UIImage(systemName: imageName), for: .normal)
            }
        }
    }
    
    var isRequired: Bool = false {
        didSet {
            requiredMarkLabel.isHidden = !isRequired
        }
    }
    
    var rightButtonAction: (() -> Void)?
    
    // MARK: - Public Access
    var inputTextField: UITextField {
        return textField
    }
    
    var inputRightButton: UIButton {
        return rightButton
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
        setupCapsuleStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupActions()
        setupCapsuleStyle()
    }
    
    private func setupCapsuleStyle() {
        textField.makeCapsule(borderColor: SHColor.GrayScale.gray_45)
    }
    
    // MARK: - Configuration
    func configure(
        placeholderText: String,
        textFieldHint: String? = nil,
        rightButtonImage: UIImage? = nil,
        isRequired: Bool = false
    ) {
        self.placeholderText = placeholderText
        self.placeholder = textFieldHint
        self.isRequired = isRequired
        
        if let image = rightButtonImage {
            rightButton.setImage(image, for: .normal)
            rightButton.isHidden = false
            setupRightButtonInTextField()
        } else {
            rightButton.isHidden = true
            textField.rightView = nil
            textField.rightViewMode = .never
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        placeholderStackView.addArrangedSubview(placeholderLabel)
        placeholderStackView.addArrangedSubview(requiredMarkLabel)
        
        addSubviews(placeholderStackView, textField, validationMessageLabel)
    }
    
    private func setupConstraints() {
        placeholderStackView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
        
        textField.snp.makeConstraints {
            $0.top.equalTo(placeholderStackView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
        
        validationMessageLabel.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(4)
            $0.trailing.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textField.updateCapsuleShape()
    }
    
    private func setupActions() {
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
    }
    
    private func setupRightButtonInTextField() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 40))
        rightButton.frame = CGRect(x: 12, y: 8, width: 24, height: 24)
        containerView.addSubview(rightButton)
        
        textField.rightView = containerView
        textField.rightViewMode = .always
    }
    
    @objc private func rightButtonTapped() {
        if !rightButton.isHidden {
            togglePasswordVisibility()
        }
        
        rightButtonAction?()
    }
    
    private func togglePasswordVisibility() {
        UIView.transition(with: textField, duration: 0.1, options: .transitionCrossDissolve) {
            self.textField.isSecureTextEntry.toggle()
        }

        let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
        UIView.transition(with: rightButton, duration: 0.4, options: .transitionFlipFromLeft) {
            self.rightButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    func updateEmailValidationUI(_ state: EmailValidationState) {
        switch state {
        case .idle:
            // 초기 상태 - 기본 테두리와 메시지 숨김
            textField.makeCapsule(borderColor: SHColor.GrayScale.gray_45)
            validationMessageLabel.isHidden = true
            
        case .checking:
            // 검사 중 - 기본 테두리 유지
            textField.makeCapsule(borderColor: SHColor.GrayScale.gray_45)
            validationMessageLabel.isHidden = true
            
        case .available:
            // 사용 가능 - 초록색 테두리와 성공 메시지
            textField.makeCapsule(borderColor: UIColor.systemGreen)
            validationMessageLabel.text = "사용 가능한 이메일입니다"
            validationMessageLabel.textColor = UIColor.systemGreen
            validationMessageLabel.isHidden = false
            
        case .unavailable:
            // 사용 불가 - 빨간색 테두리와 에러 메시지
            textField.makeCapsule(borderColor: UIColor.systemRed)
            validationMessageLabel.text = "사용이 불가능한 이메일입니다"
            validationMessageLabel.textColor = UIColor.systemRed
            validationMessageLabel.isHidden = false
            
        case let .invalid(message):
            // 잘못된 형식 - 빨간색 테두리와 에러 메시지
            textField.makeCapsule(borderColor: UIColor.systemRed)
            validationMessageLabel.text = message
            validationMessageLabel.textColor = UIColor.systemRed
            validationMessageLabel.isHidden = false
            
        case .error:
            // 네트워크 오류 - 기본 테두리와 오류 메시지
            textField.makeCapsule(borderColor: SHColor.GrayScale.gray_45)
            validationMessageLabel.text = "잠시 후 다시 시도해주세요."
            validationMessageLabel.textColor = UIColor.systemRed
            validationMessageLabel.isHidden = false
        case let .customError(message):
            
            textField.makeCapsule(borderColor: SHColor.GrayScale.gray_45)
            validationMessageLabel.text = message
            validationMessageLabel.textColor = UIColor.systemRed
            validationMessageLabel.isHidden = false
        }
    }
}
