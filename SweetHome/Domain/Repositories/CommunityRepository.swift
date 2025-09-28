//
//  CommunityRepository.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - 커뮤니티 관련 데이터 접근을 추상화하는 Repository
protocol CommunityRepository {
    /// - 커뮤니티 게시글 목록 조회
    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse>
    /// - 커뮤니티 게시글 상세 조회
    func fetchPostDetail(postId: String) -> Observable<CommunityPostsDetailResponse>
}
