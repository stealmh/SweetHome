//
//  CommunityRepository.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - 커뮤니티 관련 데이터 접근을 추상화하는 Repository
public protocol CommunityRepository {
    /// - 커뮤니티 게시글 목록 조회
    /// - Returns: 게시글 목록과 다음 커서를 포함한 튜플
    func fetchPosts() -> Observable<([CommunityPost], String)>

    /// - 커뮤니티 게시글 상세 조회
    /// - Returns: 게시글 상세 정보
    func fetchPostDetail(postId: String) -> Observable<CommunityPostDetail>
}
