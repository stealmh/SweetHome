//
//  NotificationPermissionManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import UIKit
import UserNotifications

final class NotificationPermissionManager {
    static let shared = NotificationPermissionManager()
    
    private init() {}
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            guard granted else { 
                print("알림 권한이 거부되었습니다")
                return false 
            }
            
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            return true
        } catch {
            print("알림 권한 설정 중 오류: \(error)")
            return false
        }
    }
    
    func setAPNsToken(_ deviceToken: Data) {
        FCMTokenManager.shared.setAPNsToken(deviceToken)
    }
}