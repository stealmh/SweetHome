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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        //TODO: - 삭제하기
        KeyChainManager.shared.deleteAll()
        Task {
            await configureUserNotifications()
        }
        configureKakaoSDK()
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
        storeDeviceTokenIfNeeded(deviceToken)
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
    }

    // MARK: - 알림 설정
    private func configureUserNotifications() async {
        UNUserNotificationCenter.current().delegate = self
        
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            /// - 권한 거부 시 조기 리턴
            guard granted else { return }
            
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("권한 설정 중 오류")
        }
    }

    private func storeDeviceTokenIfNeeded(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        KeyChainManager.shared.save(.deviceToken, value: tokenString)
    }

//MARK: - Core Data
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SweetHome")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("CoreData Load Error: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

//MARK: - Core Data 저장
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("CoreData Save Error: \(error), \(error.userInfo)")
            }
        }
    }
}

//MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
}
