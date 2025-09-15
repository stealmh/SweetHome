//
//  MainTabBarController.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    private var currentActiveTab: TabType = .home
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupTabBarAppearance()
        setupNotificationObservers()
        setupInitialTab()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 메인 탭바가 준비되었음을 알림
        NotificationCenter.default.post(name: .mainTabBarReady, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension MainTabBarController {
    func setupTabBar() {
        tabBar.tintColor = SHColor.GrayScale.gray_100
    }
    
    func setupInitialTab() {
        let initialControllers = [
            createViewController(for: .home),
            createPlaceholder(for: .interest),
            createPlaceholder(for: .chat),
            createPlaceholder(for: .setting)
        ]
        setViewControllers(initialControllers, animated: false)
        selectedIndex = TabType.home.rawValue
        delegate = self
    }
    
    /// - TabBar 폰트 설정
    func setupTabBarAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: SHFont.pretendard(.medium).setSHFont(.caption1) ?? UIFont.systemFont(ofSize: 10)
        ], for: .normal)

        UITabBarItem.appearance().setTitleTextAttributes([
            .font: SHFont.pretendard(.semiBold).setSHFont(.caption1) ?? UIFont.systemFont(ofSize: 10)
        ], for: .selected)
    }
    
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToChat(_:)),
            name: .Chat.navigateToChat,
            object: nil
        )
    }
    
    func createViewController(for tabType: TabType) -> UIViewController {
        let vc: UIViewController
        
        switch tabType {
        case .home:
            vc = HomeViewController()
        case .interest:
            vc = HomeViewController()
        case .chat:
            vc = ChatViewController()
        case .setting:
            vc = HomeViewController()
        }
        
        let navController = UINavigationController(rootViewController: vc)
        navController.tabBarItem = UITabBarItem(
            title: tabType.title,
            image: tabType.image,
            selectedImage: tabType.selectedImage
        )
        
        return navController
    }
    
    func createPlaceholder(for tabType: TabType) -> UIViewController {
        let placeholder = UIViewController()
        placeholder.tabBarItem = UITabBarItem(
            title: tabType.title,
            image: tabType.image,
            selectedImage: tabType.selectedImage
        )
        return placeholder
    }
    
    @objc func handleNavigateToChat(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["roomId"] as? String else { return }
        
        selectedIndex = TabType.chat.rawValue
        
        if let navController = selectedViewController as? UINavigationController,
           let chatViewController = navController.topViewController as? ChatViewController {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let chatDetailVC = ChatDetailViewController(roomId: roomId)
                navController.pushViewController(chatDetailVC, animated: true)
            }
        }
    }
}


// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedTab = TabType(rawValue: tabBarController.selectedIndex) else { return }
        
        if selectedTab != currentActiveTab {
            var newControllers: [UIViewController] = []
            
            for tabType in TabType.allCases {
                if tabType == selectedTab {
                    newControllers.append(createViewController(for: tabType))
                } else {
                    newControllers.append(createPlaceholder(for: tabType))
                }
            }
            
            setViewControllers(newControllers, animated: false)
            self.selectedIndex = selectedTab.rawValue
            currentActiveTab = selectedTab
        }
    }
}

