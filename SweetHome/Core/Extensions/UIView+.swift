//
//  UIView+.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

extension UIView {
    public func addSubviews(_ subviews: UIView...) {
        subviews.forEach(addSubview)
    }
    
    /// 뷰를 캡슐 모양으로 스타일링합니다.
    /// - Parameters:
    ///   - backgroundColor: 배경색 (기본값: SHColor.GrayScale.gray_0)
    ///   - borderColor: 테두리 색상 (기본값: SHColor.Brand.deepCream)
    ///   - borderWidth: 테두리 두께 (기본값: 1.5)
    func makeCapsule(
        backgroundColor: UIColor = SHColor.GrayScale.gray_0,
        borderColor: UIColor = SHColor.Brand.deepCream,
        borderWidth: CGFloat = 1.5
    ) {
        self.backgroundColor = backgroundColor
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        // 높이의 절반을 cornerRadius로 설정하여 캡슐 모양 생성
        self.layer.cornerRadius = self.bounds.height / 2
        
        // 레이아웃이 변경될 때마다 cornerRadius를 업데이트
        self.clipsToBounds = true
    }
    
    /// 레이아웃이 변경된 후 캡슐 모양을 유지하기 위해 cornerRadius를 업데이트합니다.
    func updateCapsuleShape() {
        self.layer.cornerRadius = self.bounds.height / 2
    }
}

extension UIStackView {
    public func addArrangeSubviews(_ subviews: UIView...) {
        subviews.forEach(addArrangedSubview)
    }
}
