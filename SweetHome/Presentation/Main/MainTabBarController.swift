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
    }
    
    private func setupTabBar() {
        // Home Tab
        let homeVC = ViewController()
        let homeNavController = UINavigationController(rootViewController: homeVC)
        homeNavController.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // Search Tab
        let searchVC = ViewController()
        let searchNavController = UINavigationController(rootViewController: searchVC)
        searchNavController.tabBarItem = UITabBarItem(
            title: "검색",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        // Favorites Tab
        let favoritesVC = ViewController()
        let favoritesNavController = UINavigationController(rootViewController: favoritesVC)
        favoritesNavController.tabBarItem = UITabBarItem(
            title: "즐겨찾기",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        
        // Profile Tab
        let profileVC = ViewController()
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem = UITabBarItem(
            title: "프로필",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        
        viewControllers = [
            homeNavController,
            searchNavController,
            favoritesNavController,
            profileNavController
        ]
        
        // Tab Bar 스타일 설정
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .systemBackground
    }
}
