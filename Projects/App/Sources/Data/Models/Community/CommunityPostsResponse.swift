//
//  CommunityPostsResponse.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation

struct CommunityPostsResponse: Decodable {
    let data: [CommunityPostsDataResponse]
    let next_cursor: String
}

struct CommunityPostsDataResponse: Decodable {
    let post_id: String
    let category: String
    let title: String
    let content: String
    let geolocation: BaseGeolocationResponse
    let creator: ParticipantResponse
    let files: [String]
    let is_like: Bool
    let like_count: Int
    let createdAt: String
    let updatedAt: String
}

// MARK: - Domain Conversion
extension CommunityPostsDataResponse {
    var toDomain: CommunityPost {
        return CommunityPost(
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
            createdAt: self.createdAt.toISO8601Date() ?? Date(),
            updatedAt: self.updatedAt.toISO8601Date() ?? Date()
        )
    }
}
