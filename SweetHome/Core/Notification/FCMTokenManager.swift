//
//  FCMTokenManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

import FirebaseMessaging

final class FCMTokenManager: NSObject {
    static let shared = FCMTokenManager()
    
    private override init() {
        super.init()
        setupMessaging()
    }
    
    private func setupMessaging() {
        Messaging.messaging().delegate = self
    }
    
    func setAPNsToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension FCMTokenManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        
        KeyChainManager.shared.save(.fcmToken, value: fcmToken)
        
        Task {
            do {
                try await sendFCMTokenToServer(fcmToken)
            } catch {
                print("❌ FCM 토큰 서버 전송 실패: \(error)")
            }
        }
    }
    
    private func sendFCMTokenToServer(_ token: String) async throws {
        print("🚀 [SERVER] FCM 토큰 서버 전송 시작: \(token)")
        
        let request = DeviceTokenRequest(deviceToken: token)
        
        do {
            try await NetworkService.shared.noneRequest(UserEndpoint.deviceToken(request))
        } catch {
            throw error
        }
    }
}