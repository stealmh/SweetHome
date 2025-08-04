//
//  SHSearchBar.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import UIKit
import SnapKit

class SHSearchBar: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_15
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = SHColor.GrayScale.gray_45.cgColor
        return v
    }()
    
    private let searchIconImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(systemName: "magnifyingglass")
        v.tintColor = SHColor.GrayScale.gray_60
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    public let textField: UITextField = {
        let v = UITextField()
        v.placeholder = "검색어를 입력해주세요."
        v.font = SHFont.pretendard(.medium).setSHFont(.body2)
        v.textColor = SHColor.GrayScale.gray_60
        v.backgroundColor = .clear
        v.borderStyle = .none
        v.clearButtonMode = .whileEditing
        return v
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupTextFieldEvents()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupTextFieldEvents()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubviews(searchIconImageView, textField)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(40)
        }
        
        searchIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        textField.snp.makeConstraints {
            $0.leading.equalTo(searchIconImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
    }
    
    private func setupTextFieldEvents() {
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
    }
    
    // MARK: - TextField Events
    @objc private func textFieldDidBeginEditing() {
//        setFocusState(true)
    }
    
    @objc private func textFieldDidEndEditing() {
//        setFocusState(false)
    }
    
    // MARK: - Public Methods
    func configure(placeholder: String? = nil) {
        if let placeholder = placeholder {
            textField.placeholder = placeholder
        }
    }
    
    func setText(_ text: String) {
        textField.text = text
    }
    
    func getText() -> String {
        return textField.text ?? ""
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}
