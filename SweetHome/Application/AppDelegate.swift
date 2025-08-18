//
//  AppDelegate.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import CoreData
import RxKakaoSDKAuth
import RxKakaoSDKCommon
import UserNotifications
import KakaoMapsSDK
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            _ = await NotificationManager.shared.requestNotificationPermission()
        }
        configureKakaoSDK()
        FirebaseApp.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.setAPNsToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - SDK 설정
    private func configureKakaoSDK() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "NATIVE_APP_KEY") as? String else {
            fatalError("NATIVE_APP_KEY not found in Info.plist")
        }
        RxKakaoSDK.initSDK(appKey: appKey)
        
        // 카카오맵 SDK 초기화 (로그인용 앱키와 동일)
        SDKInitializer.InitSDK(appKey: appKey)
    }
}

