//
//  EstateMapFloatButton.swift
//  SweetHome
//
//  Created by 김민호 on 8/13/25.
//

import UIKit
import SnapKit

class EstateMapFloatButton: UIView {
    private let floatButton: UIButton = {
        let v = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let image = SHAsset.Icon.focus
        v.setImage(image, for: .normal)
        v.tintColor = SHColor.GrayScale.gray_75
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowOpacity = 0.15
        v.layer.shadowRadius = 8
        v.clipsToBounds = false
        
        return v
    }()
    
    var onClick: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
        setConstraints()
        setAction()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUI()
        setConstraints()
        setAction()
    }
    
    func setUI() {
        clipsToBounds = false // shadow가 보이도록 false로 설정
        layer.cornerRadius = 16
        layer.borderColor = SHColor.GrayScale.gray_45.cgColor
        layer.borderWidth = 1
        backgroundColor = .white
        addSubview(floatButton)
    }
    
    func setConstraints() {
        floatButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().inset(8)
            $0.trailing.equalToSuperview().inset(8)
            
        }
    }
    
    func setAction() {
        floatButton.addTarget(self , action: #selector(floatButtonTapped), for: .touchUpInside)
    }
    
    @objc func floatButtonTapped() {
        onClick?()
    }
}
