//
//  EstateDetailBrokerButton.swift
//  SweetHome
//
//  Created by 김민호 on 8/17/25.
//

import UIKit
import SnapKit

final class EstateDetailBrokerButton: UIView {
    
    // MARK: - Properties
    var onTapped: (() -> Void)?
    
    // MARK: - UI Components
    private let imageButton: UIButton = {
        let v = UIButton(type: .custom)
        v.backgroundColor = .clear
        v.imageView?.contentMode = .scaleToFill
        v.tintColor = .white
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
        backgroundColor = SHColor.Brand.deepCream
        layer.cornerRadius = 8
        addSubview(imageButton)
    }
    
    private func setupConstraints() {
        imageButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        
        self.snp.makeConstraints {
            $0.size.equalTo(40)
        }
    }
    
    private func setupActions() {
        imageButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        onTapped?()
    }
    
    // MARK: - Public Methods
    func configure(with image: UIImage?) {
        imageButton.setImage(image, for: .normal)
    }
}
