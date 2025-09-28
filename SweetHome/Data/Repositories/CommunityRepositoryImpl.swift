//
//  CommunityRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import Foundation
import RxSwift

/// - CommunityRepository의 구현체
final class CommunityRepositoryImpl: CommunityRepository {

    private let apiClient: ApiClientProtocol

    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }

    /// - 커뮤니티 게시글 목록 조회
    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
        return apiClient.requestObservable(CommunityEndpoint.posts(parameter: request))
    }

    /// - 커뮤니티 게시글 상세 조회
    func fetchPostDetail(postId: String) -> Observable<CommunityPostsDetailResponse> {
        return apiClient.requestObservable(CommunityEndpoint.postDetail(id: postId))
    }
}

// MARK: - Mock Data (API 실패 시 폴백용)
extension CommunityRepositoryImpl {

    private func createMockPosts() -> [CommunityPostsDataResponse] {
        return [
            CommunityPostsDataResponse(
                post_id: "1",
                category: "일반",
                title: "새 아파트 구경 갔다가 놀란 후기",
                content: "오늘 신축 아파트 구경을 갔는데 정말 깔끔하더라구요. 특히 주방이 너무 마음에 들었어요. 가격도 예상보다 합리적이었습니다.",
                geolocation: BaseGeolocationResponse(longitude: 127.0276, latitude: 37.4979),
                creator: ParticipantResponse(
                    user_id: "user1",
                    nick: "집구하는사람",
                    introduction: "집 구하는 중입니다",
                    profileImage: nil
                ),
                files: [],
                is_like: false,
                like_count: 12,
                createdAt: "2024-09-28T10:30:00Z",
                updatedAt: "2024-09-28T10:30:00Z"
            ),
            CommunityPostsDataResponse(
                post_id: "2",
                category: "질문",
                title: "전세 계약 시 주의사항이 있을까요?",
                content: "첫 전세 계약을 앞두고 있는데, 어떤 부분을 특히 주의해서 봐야 할지 궁금합니다. 경험 있으신 분들의 조언 부탁드려요!",
                geolocation: BaseGeolocationResponse(longitude: 126.9784, latitude: 37.5665),
                creator: ParticipantResponse(
                    user_id: "user2",
                    nick: "신혼부부",
                    introduction: "신혼집 구하는 중",
                    profileImage: nil
                ),
                files: [],
                is_like: true,
                like_count: 8,
                createdAt: "2024-09-28T09:15:00Z",
                updatedAt: "2024-09-28T09:15:00Z"
            ),
            CommunityPostsDataResponse(
                post_id: "3",
                category: "정보",
                title: "강남구 부동산 시세 정보 공유",
                content: "최근 강남구 일대의 부동산 시세가 많이 올랐더라구요. 제가 알아본 정보들을 공유해 드릴게요. 도움이 되셨으면 좋겠습니다.",
                geolocation: BaseGeolocationResponse(longitude: 127.0311, latitude: 37.5175),
                creator: ParticipantResponse(
                    user_id: "user3",
                    nick: "부동산전문가",
                    introduction: "부동산 업계 10년차",
                    profileImage: nil
                ),
                files: ["image1.jpg", "image2.jpg"],
                is_like: false,
                like_count: 25,
                createdAt: "2024-09-27T18:45:00Z",
                updatedAt: "2024-09-27T18:45:00Z"
            ),
            CommunityPostsDataResponse(
                post_id: "4",
                category: "후기",
                title: "이사업체 추천 후기",
                content: "최근에 이사를 했는데 정말 친절하고 꼼꼼한 업체를 만났어요. 혹시 이사 준비하시는 분들께 도움이 될까 해서 후기 남겨요.",
                geolocation: BaseGeolocationResponse(longitude: 127.0844, latitude: 37.5043),
                creator: ParticipantResponse(
                    user_id: "user4",
                    nick: "이사완료",
                    introduction: "새집 적응 중",
                    profileImage: nil
                ),
                files: [],
                is_like: true,
                like_count: 15,
                createdAt: "2024-09-27T14:20:00Z",
                updatedAt: "2024-09-27T14:20:00Z"
            )
        ]
    }

    private func createMockPostDetail(postId: String) -> CommunityPostsDetailResponse {
        let mockComments = [
            CommentResponse(
                comment_id: "comment1",
                content: "정말 유용한 정보네요! 감사합니다.",
                createdAt: "2024-09-28T11:00:00Z",
                creator: CreatorResponse(
                    user_id: "commenter1",
                    nick: "댓글러",
                    introduction: "부동산 관심많음",
                    profileImage: nil
                ),
                replies: nil
            ),
            CommentResponse(
                comment_id: "comment2",
                content: "저도 비슷한 경험이 있어요. 정말 공감됩니다.",
                createdAt: "2024-09-28T12:30:00Z",
                creator: CreatorResponse(
                    user_id: "commenter2",
                    nick: "공감왕",
                    introduction: "집구하는중",
                    profileImage: nil
                ),
                replies: nil
            )
        ]

        // 첫 번째 목 데이터를 기반으로 상세 정보 생성
        let basePost = createMockPosts().first!

        return CommunityPostsDetailResponse(
            post_id: postId,
            category: basePost.category,
            title: basePost.title,
            content: basePost.content,
            geolocation: basePost.geolocation,
            creator: basePost.creator,
            files: basePost.files,
            is_like: basePost.is_like,
            like_count: basePost.like_count,
            comments: mockComments,
            createdAt: basePost.createdAt,
            updatedAt: basePost.updatedAt
        )
    }
}

// MARK: - Empty Response for API calls that don't return data
struct EmptyResponse: Decodable {}
