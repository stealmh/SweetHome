//
//  UILabel+.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

extension UILabel {
    func setFontStyle(_ fontStyle: SHFontStyle) {
        self.font = fontStyle.font
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontStyle.lineHeight
        paragraphStyle.maximumLineHeight = fontStyle.lineHeight
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: fontStyle.font,
            .paragraphStyle: paragraphStyle,
            .kern: fontStyle.letterSpacing
        ]
        
        if let text = self.text {
            self.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }
}
