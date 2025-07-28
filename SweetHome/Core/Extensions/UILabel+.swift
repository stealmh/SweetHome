//
//  UILabel+.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

extension UILabel {
    func setFont(_ font: SHFont, size: SHFont.Size) {
        self.font = font.setSHFont(size)
    }
}
