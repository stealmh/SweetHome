//
//  SceneDelegate.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let splashViewController = SplashViewController()
        window?.rootViewController = splashViewController
        
        window?.makeKeyAndVisible()
        
        // 토큰 만료 Notification 등록
        setupTokenExpirationNotification()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if AuthApi.isKakaoTalkLoginUrl(url) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    // MARK: - Token Expiration Handling
    private func setupTokenExpirationNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshTokenExpired),
            name: .refreshTokenExpired,
            object: nil
        )
    }
    
    @objc private func handleRefreshTokenExpired() {
        guard let window = window else { return }
        
        let loginViewController = LoginViewController()
        
        window.rootViewController = loginViewController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}

