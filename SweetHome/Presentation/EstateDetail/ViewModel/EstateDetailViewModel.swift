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
        let reservationButtonTapped: Observable<Void>
        let brokerCallButtonTapped: Observable<Void>
        let brokerChatButtonTapped: Observable<Void>
        let similarCellTapped: Observable<Estate>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estateDetail: Driver<DetailEstate?>
        let backButtonTappedResult: Driver<Void>
        let reservationButtonTappedResult: Driver<Void>
        let brokerCallButtonTappedResult: Driver<Void>
        let brokerChatButtonTappedResult: Driver<Void>
        let similarCellTappedResult: Driver<Estate>
        let error: Driver<SHError>
        /// - 현재 이미지 개수 제공
        let thumbnailsCount: Driver<Int>
        /// - 유사한 매물 목록
        let similarEstates: Driver<[Estate]>
    }
    
    // MARK: - Properties
    private let apiClient: ApiClient
    private let estateDetailRelay = BehaviorSubject<DetailEstate?>(value: nil)
    private let similarEstatesRelay = BehaviorSubject<[Estate]>(value: [])
    
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
                // 유사한 매물 로드
                self?.loadSimilarEstates(errorRelay: errorRelay)
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
        
        /// - 예약하기 버튼 눌렀을 때
        let reservationButtonTapped = input.reservationButtonTapped
            .do(onNext: { _ in
                // TODO: 예약하기 기능 구현
                print("예약하기 버튼 탭됨")
            })
            .asDriver(onErrorDriveWith: .empty())
        
        /// - 중개사 전화 버튼 눌렀을 때
        let brokerCallButtonTapped = input.brokerCallButtonTapped
            .do(onNext: { _ in
                // TODO: 전화 기능 구현
                print("중개사 전화 버튼 탭됨")
            })
            .asDriver(onErrorDriveWith: .empty())
        
        /// - 중개사 채팅 버튼 눌렀을 때
        let brokerChatButtonTapped = input.brokerChatButtonTapped
            .do(onNext: { _ in
                // TODO: 채팅 기능 구현
                print("중개사 채팅 버튼 탭됨")
            })
            .asDriver(onErrorDriveWith: .empty())
        
        /// - 유사한 매물 셀 눌렀을 때
        let similarCellTapped = input.similarCellTapped
            .do(onNext: { estate in
                // TODO: 유사한 매물 상세 화면으로 이동
                print("유사한 매물 셀 탭됨: \(estate.title)")
            })
            .asDriver(onErrorDriveWith: .empty())
        
        /// - 이미지 개수 Driver
        let thumbnailsCount = estateDetailRelay
            .map { $0?.thumbnails.count ?? 0 }
            .asDriver(onErrorJustReturn: 0)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            estateDetail: estateDetailRelay.asDriver(onErrorDriveWith: .empty()),
            backButtonTappedResult: backButtonTapped,
            reservationButtonTappedResult: reservationButtonTapped,
            brokerCallButtonTappedResult: brokerCallButtonTapped,
            brokerChatButtonTappedResult: brokerChatButtonTapped,
            similarCellTappedResult: similarCellTapped,
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            thumbnailsCount: thumbnailsCount,
            similarEstates: similarEstatesRelay.asDriver(onErrorJustReturn: [])
        )
    }
    
    // MARK: - Private Methods
    private func loadSimilarEstates(errorRelay: PublishSubject<SHError>) {
        apiClient
            .requestObservable(EstateEndpoint.similarEstates)
            .map { (response: BaseEstateResponse) -> [Estate] in
                return response.data.map { $0.toDomain }
            }
            .catch { error -> Observable<[Estate]> in
                print("Similar estates error: \(error.localizedDescription)")
                errorRelay.onNext(SHError.from(error))
                return Observable.just([])
            }
            .subscribe(onNext: { [weak self] estates in
                self?.similarEstatesRelay.onNext(estates)
            })
            .disposed(by: disposeBag)
    }
}
