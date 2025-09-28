//
//  CommunityUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - CommunityUseCase의 구현체
final class CommunityUseCaseImpl: CommunityUseCase {

    private let repository: CommunityRepository

    init(repository: CommunityRepository) {
        self.repository = repository
    }

    /// - 커뮤니티 게시글 목록 조회
    func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]> {
        return repository.fetchPosts(request: request).map { $0.data.map { $0.toDomain } }
    }

    /// - 커뮤니티 게시글 상세 조회
    func fetchPostDetail(postId: String) -> Observable<CommunityPostDetail> {
        return repository.fetchPostDetail(postId: postId).map { $0.toDomain }
    }
}
