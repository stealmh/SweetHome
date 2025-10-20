//
//  MultipartFormData.swift
//  CoreNetwork
//
//  Created by 김민호 on 7/24/25.
//

import Foundation

/// - Multipart Form Data 래퍼
/// - 파일 업로드에 사용되는 데이터 구조
public struct MultipartFormData {
    public let data: Data
    public let name: String
    public let fileName: String?
    public let mimeType: String?

    public init(
        data: Data,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
