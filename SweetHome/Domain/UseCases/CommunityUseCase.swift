//
//  CommunityUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - 커뮤니티 관련 비즈니스 로직을 담당하는 UseCase
protocol CommunityUseCase {
    /// - 커뮤니티 게시글 목록 조회
    func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]>
    /// - 커뮤니티 게시글 상세 조회
    func fetchPostDetail(postId: String) -> Observable<CommunityPostDetail>
}
