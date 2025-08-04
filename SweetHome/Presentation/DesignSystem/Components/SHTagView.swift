//
//  SHTagView.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import UIKit
import SnapKit

class SHTagView: UIView {
    
    // MARK: - UI Components
    private let textLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.semiBold), size: .caption2)
        v.textColor = SHColor.Brand.brightWood
        v.textAlignment = .center
        return v
    }()
    
    // MARK: - Initialization
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
    
    convenience init(text: String) {
        self.init(frame: .zero)
        configure(text: text)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = SHColor.Brand.brightCream
        layer.cornerRadius = 4
        clipsToBounds = true
        
        addSubview(textLabel)
    }
    
    private func setupConstraints() {
        textLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(5)
        }
    }
    
    // MARK: - Override Methods
    override var intrinsicContentSize: CGSize {
        let labelSize = textLabel.intrinsicContentSize
        return CGSize(
            width: labelSize.width + 10,
            height: labelSize.height + 4
        )
    }
    
    // MARK: - Public Methods
    func configure(text: String) {
        textLabel.text = text
        invalidateIntrinsicContentSize()
    }
    
    func configure(text: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil) {
        textLabel.text = text
        invalidateIntrinsicContentSize()
        
        if let bgColor = backgroundColor {
            self.backgroundColor = bgColor
        }
        
        if let txtColor = textColor {
            textLabel.textColor = txtColor
        }
    }
}
