//
//  CommunityViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import RxSwift
import RxCocoa
import Foundation

final class CommunityViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let refresh: Observable<Void>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let posts: Driver<[CommunityPost]>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
        let selectedPost: Driver<CommunityPost>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = BehaviorRelay<Bool>(value: false)
        let postsRelay = BehaviorRelay<[CommunityPost]>(value: [])
        let errorRelay = PublishRelay<Error>()

        /// - 초기 로드 및 새로고침
        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            input.refresh
        )

        loadTrigger
            .do(onNext: { _ in loadingRelay.accept(true) })
            .flatMapLatest { _ -> Observable<[CommunityPost]> in
                /// - 목 데이터 반환 (실제로는 API 호출)
                return Observable.just(self.createMockData().map { $0.toDomain })
                    .delay(.milliseconds(500), scheduler: MainScheduler.instance)
                    .catch { error in
                        errorRelay.accept(error)
                        return Observable.just([])
                    }
            }
            .do(onNext: { _ in loadingRelay.accept(false) })
            .bind(to: postsRelay)
            .disposed(by: disposeBag)

        /// - 아이템 선택 처리
        let selectedPost = input.itemSelected
            .withLatestFrom(postsRelay) { (indexPath: IndexPath, posts: [CommunityPost]) -> CommunityPost? in
                guard indexPath.item < posts.count else { return nil }
                return posts[indexPath.item]
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            posts: postsRelay.asDriver(),
            isLoading: loadingRelay.asDriver(),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            selectedPost: selectedPost
        )
    }

    /// - 목 데이터 생성
    private func createMockData() -> [CommunityPostsDataResponse] {
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
            ),
            CommunityPostsDataResponse(
                post_id: "5",
                category: "일반",
                title: "동네 카페 추천해드려요",
                content: "저희 동네에 새로 생긴 카페인데 분위기도 좋고 커피도 맛있어요. 부동산 상담 하기에도 좋은 공간 같아서 추천드립니다!",
                geolocation: BaseGeolocationResponse(longitude: 126.9520, latitude: 37.4807),
                creator: ParticipantResponse(
                    user_id: "user5",
                    nick: "카페러버",
                    introduction: "카페 탐방이 취미",
                    profileImage: nil
                ),
                files: ["cafe1.jpg"],
                is_like: false,
                like_count: 6,
                createdAt: "2024-09-26T16:00:00Z",
                updatedAt: "2024-09-26T16:00:00Z"
            )
        ]
    }
}
