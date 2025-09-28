//
//  CommunityPostsRequest.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

struct CommunityPostsRequest: Encodable {
    /// - 한 페이지당 보여지는 게시글 개수
    let limit: Int
    /// - 다음 페이지 조회를 위한 post_id
    let next: String
}
