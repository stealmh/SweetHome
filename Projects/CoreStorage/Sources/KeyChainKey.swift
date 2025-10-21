//
//  KeyChainKey.swift
//  CoreStorage
//
//  Created by Claude on 10/21/25.
//

import Foundation

/// - KeyChain에 저장되는 키 정의
/// - App과 Auth 모듈의 모든 키를 포함
public enum KeyChainKey: String, CaseIterable, Sendable {
    // MARK: - Auth Keys (인증 관련)
    case accessToken = "accessToken"
    case refreshToken = "refreshToken"
    case userID = "userID"

    // MARK: - App Keys (앱 전용)
    case lastLoginStatus = "lastLoginStatus"
    case deviceToken = "deviceToken"
    case fcmToken = "fcmToken"
}
