//
//  Fonts.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

enum SHFont {
    private enum FontName {
        static let pretendardThin = "Pretendard-Thin"
        static let pretendardExtraLight = "Pretendard-ExtraLight"
        static let pretendardLight = "Pretendard-Light"
        static let pretendardRegular = "Pretendard-Regular"
        static let pretendardMedium = "Pretendard-Medium"
        static let pretendardSemiBold = "Pretendard-SemiBold"
        static let pretendardBold = "Pretendard-Bold"
        static let pretendardExtraBold = "Pretendard-ExtraBold"
        static let pretendardBlack = "Pretendard-Black"
        static let yeongdeokHaeparang = "Yeongdeok-Haeparang"
    }
    
    // MARK: - Pretendard Fonts
    enum Pretendard {
        static let title1 = SHFontStyle(
            font: UIFont(name: FontName.pretendardBold, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
            lineHeight: 28,
            letterSpacing: -0.2
        )
        static let body1 = SHFontStyle(
            font: UIFont(name: FontName.pretendardMedium, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium),
            lineHeight: 24,
            letterSpacing: -0.1
        )
        static let body2 = SHFontStyle(
            font: UIFont(name: FontName.pretendardMedium, size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium),
            lineHeight: 22,
            letterSpacing: -0.1
        )
        static let body3 = SHFontStyle(
            font: UIFont(name: FontName.pretendardMedium, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium),
            lineHeight: 20,
            letterSpacing: 0
        )
        static let caption1 = SHFontStyle(
            font: UIFont(name: FontName.pretendardRegular, size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .regular),
            lineHeight: 18,
            letterSpacing: 0
        )
        static let caption2 = SHFontStyle(
            font: UIFont(name: FontName.pretendardRegular, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .regular),
            lineHeight: 16,
            letterSpacing: 0
        )
        static let caption3 = SHFontStyle(
            font: UIFont(name: FontName.pretendardRegular, size: 8) ?? UIFont.systemFont(ofSize: 8, weight: .regular),
            lineHeight: 12,
            letterSpacing: 0
        )
    }
    
    // MARK: - Yeongdeok Haeparang Fonts
    enum YeongdeokHaeparang {
        static let title1 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold),
            lineHeight: 30,
            letterSpacing: -0.1
        )
        static let body1 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .regular),
            lineHeight: 26,
            letterSpacing: 0
        )
        static let body2 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .regular),
            lineHeight: 24,
            letterSpacing: 0
        )
        static let body3 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular),
            lineHeight: 22,
            letterSpacing: 0
        )
        static let caption1 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .regular),
            lineHeight: 20,
            letterSpacing: 0
        )
        static let caption2 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .regular),
            lineHeight: 18,
            letterSpacing: 0
        )
        static let caption3 = SHFontStyle(
            font: UIFont(name: FontName.yeongdeokHaeparang, size: 8) ?? UIFont.systemFont(ofSize: 8, weight: .regular),
            lineHeight: 14,
            letterSpacing: 0
        )
    }
}

struct SHFontStyle {
    let font: UIFont
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
    
    init(font: UIFont, lineHeight: CGFloat, letterSpacing: CGFloat = 0) {
        self.font = font
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }
}
