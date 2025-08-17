//
//  Fonts.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

enum SHFont {
    case pretendard(Style)
    case yeongdeok
    
    enum Size: CGFloat {
        case extra = 40
        case _30 = 30
        case title1 = 20
        case body1 = 16
        case body2 = 14
        case body3 = 13
        case caption1 = 12
        case caption2 = 10
        case caption3 = 8
    }
    
    enum Style {
        case thin
        case extraLight
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        case black
        
        var pretendardFontName: String {
            switch self {
            case .thin: return "Pretendard-Thin"
            case .extraLight: return "Pretendard-ExtraLight"
            case .light: return "Pretendard-Light"
            case .regular: return "Pretendard-Regular"
            case .medium: return "Pretendard-Medium"
            case .semiBold: return "Pretendard-SemiBold"
            case .bold: return "Pretendard-Bold"
            case .extraBold: return "Pretendard-ExtraBold"
            case .black: return "Pretendard-Black"
            }
        }
    }
    
    func setSHFont(_ size: Size) -> UIFont? {
        switch self {
        case .pretendard(let style):
            return UIFont(name: style.pretendardFontName, size: size.rawValue)
        case .yeongdeok:
            return UIFont(name: "Yeongdeok-Haeparang", size: size.rawValue)
        }
    }
}
