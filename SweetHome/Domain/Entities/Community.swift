//
//  Community.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation

// MARK: - Community Domain Models
public struct CommunityPost: Hashable {
    public let id: String
    public let category: String
    public let title: String
    public let content: String
    public let geolocation: Geolocation
    public let creator: Creator
    public let files: [String]
    public let isLike: Bool
    public let likeCount: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, category: String, title: String, content: String, geolocation: Geolocation, creator: Creator, files: [String], isLike: Bool, likeCount: Int, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.category = category
        self.title = title
        self.content = content
        self.geolocation = geolocation
        self.creator = creator
        self.files = files
        self.isLike = isLike
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CommunityPostDetail: Hashable {
    public let id: String
    public let category: String
    public let title: String
    public let content: String
    public let geolocation: Geolocation
    public let creator: Creator
    public let files: [String]
    public let isLike: Bool
    public let likeCount: Int
    public let comments: [CommunityComment]
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: String, category: String, title: String, content: String, geolocation: Geolocation, creator: Creator, files: [String], isLike: Bool, likeCount: Int, comments: [CommunityComment], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.category = category
        self.title = title
        self.content = content
        self.geolocation = geolocation
        self.creator = creator
        self.files = files
        self.isLike = isLike
        self.likeCount = likeCount
        self.comments = comments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CommunityComment: Hashable {
    public let commentId: String
    public let content: String
    public let creator: Creator
    public let createdAt: Date
    public let updatedAt: Date

    public init(commentId: String, content: String, creator: Creator, createdAt: Date, updatedAt: Date) {
        self.commentId = commentId
        self.content = content
        self.creator = creator
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Extensions
public extension CommunityPost {
    /// - 시간 표시용 문자열
    var timeAgoText: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)

        if timeInterval < 60 {
            return "방금 전"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)일 전"
        }
    }

    /// - 첨부파일 개수 표시용 문자열
    var fileCountText: String? {
        guard !files.isEmpty else { return nil }
        return "📷 \(files.count)"
    }

    /// - 내용 미리보기 (3줄 제한)
    var contentPreview: String {
        let lines = content.components(separatedBy: .newlines)
        let limitedLines = Array(lines.prefix(3))
        let preview = limitedLines.joined(separator: "\n")

        if lines.count > 3 || preview.count > 150 {
            let truncated = String(preview.prefix(150))
            return truncated + "..."
        }
        return preview
    }
}

public extension CommunityComment {
    /// - 시간 표시용 문자열
    var timeAgoText: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)

        if timeInterval < 60 {
            return "방금 전"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)일 전"
        }
    }
}

public extension Date {
    /// - 시간 표시용 문자열
    var timeAgoText: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)

        if timeInterval < 60 {
            return "방금 전"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)일 전"
        }
    }
}
