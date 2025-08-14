//
//  EstateMapSliderComponent.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import SnapKit

class EstateMapSliderComponent: UIView {
    
    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = SHColor.GrayScale.gray_60
        return v
    }()
    
    private let componentLabel: UILabel = {
        let v = UILabel()
        v.setFont(.pretendard(.medium), size: .caption2)
        v.textColor = SHColor.GrayScale.gray_60
        v.textAlignment = .center
        return v
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setUI() {
        addSubviews(dividerView, componentLabel)
    }
    
    func setConstraints() {
        dividerView.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(6)
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
        }
        
        componentLabel.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(4)
            $0.bottom.centerX.equalToSuperview()
        }
    }
    
    func configure(value: String) {
        componentLabel.text = value
        
        DispatchQueue.main.async {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}
