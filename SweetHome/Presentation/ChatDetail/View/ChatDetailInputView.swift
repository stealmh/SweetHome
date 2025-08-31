//
//  ChatDetailInputView.swift
//  SweetHome
//
//  Created by 김민호 on 8/25/25.
//

import UIKit
import SnapKit

final class ChatDetailInputView: UIView {
    
    let messageTextView: UITextView = {
        let v = UITextView()
        v.font = .systemFont(ofSize: 16)
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 20
        v.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        v.isScrollEnabled = false
        v.showsVerticalScrollIndicator = false
        return v
    }()
    
    let addPhotoButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        v.tintColor = .systemGray
        v.contentVerticalAlignment = .fill
        v.contentHorizontalAlignment = .fill
        return v
    }()
    
    let sendButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("전송", for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 20
        v.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return v
    }()
    
    private var messageTextViewBottomConstraint: Constraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        addSubviews(addPhotoButton, messageTextView, sendButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addTopShadow()
    }
    
    private func addTopShadow() {
        let shadowPath = UIBezierPath()
        shadowPath.move(to: CGPoint(x: 0, y: 0))
        shadowPath.addLine(to: CGPoint(x: bounds.width, y: 0))
        shadowPath.addLine(to: CGPoint(x: bounds.width, y: -2))
        shadowPath.addLine(to: CGPoint(x: 0, y: -2))
        shadowPath.close()
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
        layer.shadowPath = shadowPath.cgPath
        layer.masksToBounds = false
    }
    
    private func setupConstraints() {
        addPhotoButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.bottom.equalTo(messageTextView.snp.bottom)
            $0.width.height.equalTo(28)
        }
        
        messageTextView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalTo(addPhotoButton.snp.trailing).offset(4)
            messageTextViewBottomConstraint = $0.bottom.equalToSuperview().constraint
            $0.height.greaterThanOrEqualTo(40)
            $0.height.lessThanOrEqualTo(100)
        }
        
        sendButton.snp.makeConstraints {
            $0.leading.equalTo(messageTextView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(8)
            $0.bottom.equalTo(messageTextView.snp.bottom)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }
    }
    
    // MARK: - Public Methods
    func clearText() {
        messageTextView.text = ""
    }
    
    func updateForKeyboardState(isKeyboardVisible: Bool) {
        let bottomInset: CGFloat = isKeyboardVisible ? 8 : 0
        messageTextViewBottomConstraint.update(inset: bottomInset)
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}
