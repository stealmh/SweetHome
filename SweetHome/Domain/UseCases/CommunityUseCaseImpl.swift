//
//  CommunityUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - CommunityUseCase의 구현체
public final class CommunityUseCaseImpl: CommunityUseCase {

    private let repository: CommunityRepository

    public init(repository: CommunityRepository) {
        self.repository = repository
    }

    /// - 커뮤니티 게시글 목록 조회
    public func fetchPosts() -> Observable<[CommunityPost]> {
        return repository.fetchPosts()
            .map { (posts, _) in posts }
    }

    /// - 커뮤니티 게시글 상세 조회
    public func fetchPostDetail(postId: String) -> Observable<CommunityPostDetail> {
        return repository.fetchPostDetail(postId: postId)
    }
}
