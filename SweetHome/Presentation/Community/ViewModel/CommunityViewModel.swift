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
    private let useCase: CommunityUseCase

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

    init(useCase: CommunityUseCase = CommunityUseCaseImpl(repository: CommunityRepositoryImpl())) {
        self.useCase = useCase
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
                return self.useCase.fetchPosts()
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
}
