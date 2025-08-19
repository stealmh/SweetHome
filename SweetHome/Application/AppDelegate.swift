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
    
    // 백그라운드에서 푸시 알림 수신 시 호출
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("백그라운드 푸시 알림 수신: \(userInfo)")
        
        // 채팅 메시지 푸시 알림인지 확인
        if let roomId = userInfo["room_id"] as? String {
            NotificationManager.shared.handleBackgroundChatNotification(userInfo)
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
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

