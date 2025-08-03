//
//  SplashViewController.swift
//  SweetHome
//
//  Created by Claude on 8/3/25.
//

import UIKit
import SnapKit

class SplashViewController: BaseViewController {
    private let appNameLabel: UILabel = {
        let v = UILabel()
        v.text = "Sweet Home"
        v.setFont(.yeongdeok, size: .extra)
        v.textColor = SHColor.Brand.deepWood
        v.textAlignment = .center
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkLoginStatusAndNavigate()
        }
    }
    
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = SHColor.Brand.brightCream
        view.addSubview(appNameLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        appNameLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

// MARK: - Navigation
private extension SplashViewController {
    func checkLoginStatusAndNavigate() {
        if isUserLoggedIn() {
            navigateToMain()
        } else {
            navigateToLogin()
        }
    }
    
    func isUserLoggedIn() -> Bool {
        guard let _ = KeyChainManager.shared.read(.accessToken),
              let _ = KeyChainManager.shared.read(.refreshToken) else { return false }
        return true
    }
    
    func navigateToMain() {
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
        
        let mainTabBarController = MainTabBarController()
        
        UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve) {
            sceneDelegate.window?.rootViewController = mainTabBarController
        }
    }
    
    func navigateToLogin() {
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
        
        let loginViewController = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        
        UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve) {
            sceneDelegate.window?.rootViewController = navigationController
        }
    }
}
