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
    private var pendingNotificationUserInfo: [AnyHashable: Any]?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let splashViewController = SplashViewController()
        window?.rootViewController = splashViewController
        
        window?.makeKeyAndVisible()
        
        // 토큰 만료 Notification 등록
        setupTokenExpirationNotification()
        
        /// - 푸시 알림으로 앱을 실행했을 때
        checkForPendingNotification(connectionOptions: connectionOptions)
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
    
    // MARK: - Push Notification Handling
    private func checkForPendingNotification(connectionOptions: UIScene.ConnectionOptions) {
        /// - 푸시 알림으로 실행된 경우
        if let notificationResponse = connectionOptions.notificationResponse {
            let userInfo = notificationResponse.notification.request.content.userInfo
            print("앱이 종료된 상태에서 푸시 알림으로 실행됨: \(userInfo)")
            
            /// - 푸시 데이터를 저장, 메인 화면이 준비되면 처리
            pendingNotificationUserInfo = userInfo

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMainTabBarReady),
                name: .mainTabBarReady,
                object: nil
            )
        }
    }
    
    @objc private func handleMainTabBarReady() {
        guard let userInfo = pendingNotificationUserInfo else { return }
        
        print("메인 탭바가 준비되었으므로 푸시 알림 처리 시작")
        
        // 지연 후 내비게이션 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationNavigator.shared.handleNotificationTap(userInfo)
        }
        
        // 처리 완료 후 데이터 정리
        pendingNotificationUserInfo = nil
        NotificationCenter.default.removeObserver(self, name: .mainTabBarReady, object: nil)
    }
}

