//
//  DeviceTokenRequest.swift
//  Auth
//
//  Created by 김민호 on 8/27/25.
//

import Foundation

public struct DeviceTokenRequest: Encodable {
    public let deviceToken: String

    public init(deviceToken: String) {
        self.deviceToken = deviceToken
    }
}
