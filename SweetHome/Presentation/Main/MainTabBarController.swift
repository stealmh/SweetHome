//
//  MainTabBarController.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupTabBarAppearance()
    }
    
    private func setupTabBar() {
        /// - 홈
        let homeVC = HomeViewController()
        let homeNavController = UINavigationController(rootViewController: homeVC)
        homeNavController.tabBarItem = UITabBarItem(
            title: "홈",
            image: SHAsset.TabBar.homeEmpty?.resized(to: 28),
            selectedImage: SHAsset.TabBar.homeFill?.resized(to: 28)
        )
        
        /// - 관심매물
        let searchVC = HomeViewController()
        let searchNavController = UINavigationController(rootViewController: searchVC)
        searchNavController.tabBarItem = UITabBarItem(
            title: "관심매물",
            image: SHAsset.TabBar.interestEmpty?.resized(to: 28),
            selectedImage: SHAsset.TabBar.interestFill?.resized(to: 28)
        )
        
        /// - 채팅
        let favoritesVC = ChatViewController()
        let favoritesNavController = UINavigationController(rootViewController: favoritesVC)
        favoritesNavController.tabBarItem = UITabBarItem(
            title: "채팅",
            image: UIImage(systemName: "message")?.resized(to: 28),
            selectedImage: UIImage(systemName: "message.fill")?.resized(to: 28)
        )
        
        //TODO: SettingVC 구현
        /// - 세팅
        let profileVC = HomeViewController()
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem = UITabBarItem(
            title: "설정",
            image: SHAsset.TabBar.settingEmpty?.resized(to: 28),
            selectedImage: SHAsset.TabBar.settingFill?.resized(to: 28)
        )
        
        viewControllers = [
            homeNavController,
            searchNavController,
            favoritesNavController,
            profileNavController
        ]
        
        tabBar.tintColor = SHColor.GrayScale.gray_100
        
    }
    
    /// - TabBar 폰트 설정
    private func setupTabBarAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: SHFont.pretendard(.medium).setSHFont(.caption1) ?? UIFont.systemFont(ofSize: 10)
        ], for: .normal)

        UITabBarItem.appearance().setTitleTextAttributes([
            .font: SHFont.pretendard(.semiBold).setSHFont(.caption1) ?? UIFont.systemFont(ofSize: 10)
        ], for: .selected)
    }
}
