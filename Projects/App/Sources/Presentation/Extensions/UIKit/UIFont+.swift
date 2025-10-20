//
//  UIFont+.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

extension UIFont {
    func setFont(_ font: SHFont, size: SHFont.Size) -> UIFont? {
        return font.setSHFont(size)
    }
    
    static func setFont(_ font: SHFont, size: SHFont.Size) -> UIFont? {
        return font.setSHFont(size)
    }
}

extension UILabel {
    func setFont(_ font: SHFont, size: SHFont.Size) {
        self.font = font.setSHFont(size)
    }
}

extension UITextField {
    func setFont(_ font: SHFont, size: SHFont.Size) {
        self.font = font.setSHFont(size)
    }
}

extension UIButton {
    func setTitleFont(_ font: SHFont, size: SHFont.Size) {
        if #available(iOS 15.0, *), var config = self.configuration {
            // Configuration 기반 버튼
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = font.setSHFont(size)
                return outgoing
            }
            self.configuration = config
        } else {
            // 기존 방식
            self.titleLabel?.font = font.setSHFont(size)
        }
    }
}
