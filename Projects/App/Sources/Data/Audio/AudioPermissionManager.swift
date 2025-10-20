//
//  AudioPermissionManager.swift
//  SweetHome
//
//  Created by 김민호 on 9/27/25.
//

import Foundation
import UIKit
import AVFoundation

final class AudioPermissionManager {

    static let shared = AudioPermissionManager()

    private init() {}

    // MARK: - Permission Status

    /// - 현재 마이크 권한 상태 확인
    var permissionStatus: AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    /// - 마이크 권한이 허용되었는지 확인
    var isPermissionGranted: Bool {
        return permissionStatus == .granted
    }

    /// - 마이크 권한이 거부되었는지 확인
    var isPermissionDenied: Bool {
        return permissionStatus == .denied
    }

    /// - 마이크 권한이 아직 요청되지 않았는지 확인
    var isPermissionUndetermined: Bool {
        return permissionStatus == .undetermined
    }

    // MARK: - Permission Request

    /// - 마이크 권한 요청
    /// - Returns: 권한 허용 여부
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// - 마이크 권한 확인 및 요청
    /// - 이미 허용된 경우 즉시 true 반환, 그렇지 않으면 권한 요청
    func checkAndRequestPermission() async throws -> Bool {
        switch permissionStatus {
        case .granted:
            return true
        case .denied:
            throw SHError.voiceRecordingError(.permissionDenied)
        case .undetermined:
            let granted = await requestPermission()
            if !granted {
                throw SHError.voiceRecordingError(.permissionDenied)
            }
            return granted
        @unknown default:
            throw SHError.voiceRecordingError(.permissionDenied)
        }
    }

    // MARK: - Settings Navigation

    /// - 설정 앱의 해당 앱 권한 화면으로 이동
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - Permission Alert Helper

    /// - 권한 거부 시 사용자에게 보여줄 알림 정보 생성
    func createPermissionDeniedAlertInfo() -> (title: String, message: String, settingsAction: String, cancelAction: String) {
        return (
            title: "마이크 권한 필요",
            message: "음성 메시지를 녹음하려면 마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            settingsAction: "설정으로 이동",
            cancelAction: "취소"
        )
    }
}
