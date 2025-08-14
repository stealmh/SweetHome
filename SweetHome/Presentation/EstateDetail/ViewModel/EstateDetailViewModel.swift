//
//  EstateDetailViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import Foundation
import RxSwift
import RxCocoa

class EstateDetailViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let viewDidLoad: Observable<String> // estateID
        let favoriteButtonTapped: Observable<Void>
        let backButtonTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estateDetail: Driver<DetailEstate?>
        let backButtonTappedResult: Driver<Void>
        let error: Driver<SHError>
    }
    
    // MARK: - Properties
    private let apiClient: ApiClient
    private let estateDetailRelay = BehaviorSubject<DetailEstate?>(value: nil)
    
    // MARK: - Initialization
    init(apiClient: ApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let errorRelay = PublishSubject<SHError>()
        
        /// - 매물 상세정보 조회, EstateID를 받아 서버에 API호출
        input.viewDidLoad
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] estateID -> Observable<DetailEstateResponse> in
                guard let self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }
                
                return self.apiClient
                    .requestObservable(EstateEndpoint.detail(id: estateID))
                    .catch { error -> Observable<DetailEstateResponse> in
                        print(error.localizedDescription)
                        errorRelay.onNext(SHError.from(error))
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] detail in
                self?.estateDetailRelay.onNext(detail.toDomain)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        /// - 좋아요 버튼 눌렀을 때
        input.favoriteButtonTapped
            .withLatestFrom(estateDetailRelay) { _, detail in detail }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] currentDetail in
                guard let self else {
                    errorRelay.onNext(SHError.commonError(.weakSelfFailure))
                    return
                }
                
                let newLikeStatus = !currentDetail.isLiked
                
                let optimisticDetail = DetailEstate(
                    id: currentDetail.id,
                    category: currentDetail.category,
                    title: currentDetail.title,
                    introduction: currentDetail.introduction,
                    reservationPrice: currentDetail.reservationPrice,
                    thumbnails: currentDetail.thumbnails,
                    description: currentDetail.description,
                    deposit: currentDetail.deposit,
                    monthlyRent: currentDetail.monthlyRent,
                    builtYear: currentDetail.builtYear,
                    maintenanceFee: currentDetail.maintenanceFee,
                    area: currentDetail.area,
                    parkingCount: currentDetail.parkingCount,
                    floors: currentDetail.floors,
                    options: currentDetail.options,
                    geolocation: currentDetail.geolocation,
                    creator: currentDetail.creator,
                    isLiked: newLikeStatus,
                    isReserved: currentDetail.isReserved,
                    likeCount: newLikeStatus ? currentDetail.likeCount + 1 : currentDetail.likeCount - 1,
                    isSafeEstate: currentDetail.isSafeEstate,
                    isRecommended: currentDetail.isRecommended,
                    comments: currentDetail.comments,
                    createdAt: currentDetail.createdAt,
                    updatedAt: currentDetail.updatedAt
                )
                
                /// - UI 즉시 반영
                self.estateDetailRelay.onNext(optimisticDetail)
                
                let requestBody = DetailEstateLikeStatus(like_status: newLikeStatus)
                self.apiClient
                    .requestObservable(EstateEndpoint.like(id: currentDetail.id, body: requestBody))
                    .map { (_: DetailEstateLikeStatus) in }
                    .catch { error -> Observable<Void> in
                        self.estateDetailRelay.onNext(currentDetail)
                        errorRelay.onNext(SHError.from(error))
                        return Observable.empty()
                    }
                    .subscribe()
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        
        /// - 뒤로가기 버튼 눌렀을 때
        let backButtonTapped = input.backButtonTapped.asDriver(onErrorDriveWith: .empty())
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            estateDetail: estateDetailRelay.asDriver(onErrorDriveWith: .empty()),
            backButtonTappedResult: backButtonTapped,
            error: errorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
