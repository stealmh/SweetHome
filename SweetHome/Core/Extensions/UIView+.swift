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
}
