//
//  CommunityDetailViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 9/28/25.
//

import RxSwift
import RxCocoa
import Foundation

final class CommunityDetailViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    private let initialPost: CommunityPost
    private let useCase: CommunityUseCase

    struct Input {
        let viewDidLoad: Observable<Void>
        let likeButtonTapped: Observable<Void>
        let commentText: Observable<String>
        let sendComment: Observable<Void>
    }

    struct Output {
        let postDetail: Driver<CommunityPostDetail>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
        let isLiked: Driver<Bool>
        let likeCount: Driver<Int>
        let commentSent: Driver<Void>
    }

    init(post: CommunityPost, useCase: CommunityUseCase = CommunityUseCaseImpl(repository: CommunityRepositoryImpl())) {
        self.initialPost = post
        self.useCase = useCase
    }

    func transform(input: Input) -> Output {
        let loadingRelay = BehaviorRelay<Bool>(value: false)
        let postDetailRelay = BehaviorRelay<CommunityPostDetail?>(value: nil)
        let errorRelay = PublishRelay<Error>()
        let isLikedRelay = BehaviorRelay<Bool>(value: initialPost.isLike)
        let likeCountRelay = BehaviorRelay<Int>(value: initialPost.likeCount)
        let commentSentRelay = PublishRelay<Void>()

        /// - 초기 데이터 로드
        input.viewDidLoad
            .do(onNext: { _ in loadingRelay.accept(true) })
            .flatMapLatest { _ -> Observable<CommunityPostDetail> in
                return self.useCase.fetchPostDetail(postId: self.initialPost.id)
                    .catch { error in
                        errorRelay.accept(error)
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in loadingRelay.accept(false) })
            .bind(to: postDetailRelay)
            .disposed(by: disposeBag)

        /// - 좋아요 버튼 처리
        input.likeButtonTapped
            .withLatestFrom(isLikedRelay)
            .flatMapLatest { currentLikeStatus -> Observable<Void> in
                return Observable.empty()
            }
            .subscribe()
            .disposed(by: disposeBag)

        /// - 댓글 전송 처리
        let validCommentText = input.commentText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        input.sendComment
            .withLatestFrom(validCommentText)
            .flatMapLatest { commentText -> Observable<Void> in
                return Observable.empty()
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(
            postDetail: postDetailRelay.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            isLoading: loadingRelay.asDriver(),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            isLiked: isLikedRelay.asDriver(),
            likeCount: likeCountRelay.asDriver(),
            commentSent: commentSentRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
