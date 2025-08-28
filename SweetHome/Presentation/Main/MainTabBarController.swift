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
        setupNotificationObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 메인 탭바가 준비되었음을 알림
        NotificationCenter.default.post(name: .mainTabBarReady, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    // MARK: - Notification Setup
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToChat(_:)),
            name: .Chat.navigateToChat,
            object: nil
        )
    }
    
    @objc private func handleNavigateToChat(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["roomId"] as? String else { return }
        
        // 채팅 탭으로 이동 (인덱스 2)
        selectedIndex = 2
        
        // 채팅 상세 화면으로 이동
        if let navController = selectedViewController as? UINavigationController,
           let chatViewController = navController.topViewController as? ChatViewController {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let chatDetailVC = ChatDetailViewController(roomId: roomId)
                navController.pushViewController(chatDetailVC, animated: true)
            }
        }
    }
}
