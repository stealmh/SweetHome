//
//  SceneDelegate.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import KakaoSDKAuth
import iamport_ios

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
            Iamport.shared.receivedURL(url)
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

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 앱이 포그라운드로 돌아올 때 안읽음 카운트 동기화
        NotificationManager.shared.syncUnreadCountsOnForeground()
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = self.window else { return }
    
            let loginViewController = LoginViewController()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = loginViewController
            }) { _ in
                window.makeKeyAndVisible()
            }
        }
    }
}

