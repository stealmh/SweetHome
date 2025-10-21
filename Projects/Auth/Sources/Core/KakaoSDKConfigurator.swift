//
//  KakaoSDKConfigurator.swift
//  Auth
//
//  Created by 김민호 on 10/21/25.
//

import Foundation
import RxKakaoSDKAuth
import RxKakaoSDKCommon

public final class KakaoSDKConfigurator {

    public static func configure() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "NATIVE_APP_KEY") as? String else {
            fatalError("NATIVE_APP_KEY not found in Info.plist")
        }

        /// - Kakao 로그인 SDK 초기화
        RxKakaoSDK.initSDK(appKey: appKey)
    }

    public static func configure(with appKey: String) {
        /// - Kakao 로그인 SDK 초기화
        RxKakaoSDK.initSDK(appKey: appKey)
    }
}
