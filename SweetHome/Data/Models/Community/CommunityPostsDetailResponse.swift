//
//  CommunityPostsDetailResponse.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation

struct CommunityPostsDetailResponse: Decodable {
    let post_id: String
    let category: String
    let title: String
    let content: String
    let geolocation: BaseGeolocationResponse
    let creator: ParticipantResponse
    let files: [String]
    let is_like: Bool
    let like_count: Int
    let comments: [CommentResponse]
    let createdAt: String
    let updatedAt: String
}

// MARK: - Domain Conversion
extension CommunityPostsDetailResponse {
    var toDomain: CommunityPostDetail {
        return CommunityPostDetail(
            id: self.post_id,
            category: self.category,
            title: self.title,
            content: self.content,
            geolocation: Geolocation(
                lon: self.geolocation.longitude,
                lat: self.geolocation.latitude
            ),
            creator: Creator(
                userId: self.creator.user_id,
                nick: self.creator.nick,
                introduction: self.creator.introduction,
                profileImage: self.creator.profileImage
            ),
            files: self.files,
            isLike: self.is_like,
            likeCount: self.like_count,
            comments: self.comments.map { $0.toCommunityDomain },
            createdAt: self.createdAt.toISO8601Date() ?? Date(),
            updatedAt: self.updatedAt.toISO8601Date() ?? Date()
        )
    }
}

extension CommentResponse {
    var toCommunityDomain: CommunityComment {
        return CommunityComment(
            commentId: self.comment_id,
            content: self.content,
            creator: Creator(
                userId: self.creator.user_id,
                nick: self.creator.nick,
                introduction: self.creator.introduction,
                profileImage: self.creator.profileImage
            ),
            createdAt: self.createdAt.toISO8601Date() ?? Date(),
            updatedAt: self.createdAt.toISO8601Date() ?? Date() // updatedAt이 없으므로 createdAt 사용
        )
    }
}
