//
//  TabType.swift
//  SweetHome
//
//  Created by 김민호 on 9/4/25.
//

import UIKit

enum TabType: Int, CaseIterable {
    case home = 0
    case interest
    case chat
    case setting
    
    var title: String {
        switch self {
        case .home: return "홈"
        case .interest: return "관심매물"
        case .chat: return "채팅"
        case .setting: return "설정"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .home: return SHAsset.TabBar.homeEmpty?.resized(to: 28)
        case .interest: return SHAsset.TabBar.interestEmpty?.resized(to: 28)
        case .chat: return UIImage(systemName: "message")?.resized(to: 28)
        case .setting: return SHAsset.TabBar.settingEmpty?.resized(to: 28)
        }
    }
    
    var selectedImage: UIImage? {
        switch self {
        case .home: return SHAsset.TabBar.homeFill?.resized(to: 28)
        case .interest: return SHAsset.TabBar.interestFill?.resized(to: 28)
        case .chat: return UIImage(systemName: "message.fill")?.resized(to: 28)
        case .setting: return SHAsset.TabBar.settingFill?.resized(to: 28)
        }
    }
}
