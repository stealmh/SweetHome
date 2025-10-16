//
//  File.swift
//  SweetHome
//
//  Created by 김민호 on 10/16/25.
//

import Foundation

// MARK: - File Domain Models

/// - 파일 업로드 정보
public struct FileUpload {
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
