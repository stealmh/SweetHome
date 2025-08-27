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
        let iamportResponse: Observable<PaymentIamportResponse>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estateDetail: Driver<DetailEstate?>
        let backButtonTappedResult: Driver<Void>
        let reservationButtonTappedResult: Driver<(OrderResponse, estateName: String)>
        let brokerCallButtonTappedResult: Driver<Void>
        let brokerChatButtonTappedResult: Driver<Void>
        let similarCellTappedResult: Driver<Estate>
        let error: Driver<SHError>
        /// - 현재 이미지 개수 제공
        let thumbnailsCount: Driver<Int>
        /// - 유사한 매물 목록
        let similarEstates: Driver<[Estate]>
        /// - 결제 검증 결과
        let paymentResult: Driver<PaymentValidationResponse?>
        let paymentError: Driver<SHError?>
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
        
        /// - 매물 상세정보 조회
        handleEstateDetailLoad(input.viewDidLoad, isLoadingRelay: isLoadingRelay, errorRelay: errorRelay)
        
        /// - 좋아요 버튼 처리
        handleFavoriteButtonTapped(input.favoriteButtonTapped, errorRelay: errorRelay)
        
        /// - 버튼 액션 처리
        let backButtonTapped = input.backButtonTapped.asDriver(onErrorDriveWith: .empty())
        let reservationButtonTapped = handleReservationButtonTapped(input.reservationButtonTapped, errorRelay: errorRelay)
        let brokerCallButtonTapped = handleBrokerCallButtonTapped(input.brokerCallButtonTapped)
        let brokerChatButtonTapped = handleBrokerChatButtonTapped(input.brokerChatButtonTapped)
        let similarCellTapped = handleSimilarCellTapped(input.similarCellTapped)
        
        /// - 결제 검증 처리
        let paymentValidationResult = self.handlePaymentValidation(input.iamportResponse, errorRelay: errorRelay)
        
        /// - 이미지 개수
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
            similarEstates: similarEstatesRelay.asDriver(onErrorJustReturn: []),
            paymentResult: paymentValidationResult.success.asDriver(onErrorJustReturn: nil),
            paymentError: paymentValidationResult.error.asDriver(onErrorJustReturn: nil)
        )
    }
    
    // MARK: - Private Methods
    
    /// 매물 상세정보 로드 처리
    private func handleEstateDetailLoad(
        _ viewDidLoad: Observable<String>,
        isLoadingRelay: BehaviorSubject<Bool>,
        errorRelay: PublishSubject<SHError>
    ) {
        viewDidLoad
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] estateID -> Observable<DetailEstateResponse> in
                guard let self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }
                
                return self.apiClient
                    .requestObservable(EstateEndpoint.detail(id: estateID))
                    .catch { error -> Observable<DetailEstateResponse> in
                        print("❌ 매물 상세정보 로드 실패: \(error.localizedDescription)")
                        errorRelay.onNext(SHError.from(error))
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] detail in
                self?.estateDetailRelay.onNext(detail.toDomain)
                self?.loadSimilarEstates(errorRelay: errorRelay)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
    }
    
    /// 좋아요 버튼 처리
    private func handleFavoriteButtonTapped(
        _ favoriteButtonTapped: Observable<Void>,
        errorRelay: PublishSubject<SHError>
    ) {
        favoriteButtonTapped
            .withLatestFrom(estateDetailRelay) { _, detail in detail }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] currentDetail in
                self?.toggleFavoriteStatus(for: currentDetail, errorRelay: errorRelay)
            })
            .disposed(by: disposeBag)
    }
    
    /// 좋아요 상태 토글
    private func toggleFavoriteStatus(
        for currentDetail: DetailEstate,
        errorRelay: PublishSubject<SHError>
    ) {
        let newLikeStatus = !currentDetail.isLiked
        let optimisticDetail = createOptimisticDetail(from: currentDetail, newLikeStatus: newLikeStatus)
        
        /// - UI는 바로 반영하기
        estateDetailRelay.onNext(optimisticDetail)
        
        let requestBody = DetailEstateLikeStatus(like_status: newLikeStatus)
        apiClient
            .requestObservable(EstateEndpoint.like(id: currentDetail.id, body: requestBody))
            .map { (_: DetailEstateLikeStatus) in }
            .catch { [weak self] error -> Observable<Void> in
                /// - 실패 시 원래 상태로 복원
                self?.estateDetailRelay.onNext(currentDetail)
                errorRelay.onNext(SHError.from(error))
                return Observable.empty()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    /// 낙관적 업데이트를 위한 DetailEstate 생성
    private func createOptimisticDetail(
        from currentDetail: DetailEstate,
        newLikeStatus: Bool
    ) -> DetailEstate {
        return DetailEstate(
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
    }
    
    /// 예약하기 버튼 처리
    private func handleReservationButtonTapped(
        _ reservationButtonTapped: Observable<Void>,
        errorRelay: PublishSubject<SHError>
    ) -> Driver<(OrderResponse, estateName: String)> {
        return reservationButtonTapped
            .withLatestFrom(estateDetailRelay) { _, detail in detail }
            .compactMap { $0 }
            .flatMapLatest { [weak self] estate -> Observable<(OrderResponse, estateName: String)> in
                guard let self else {
                    errorRelay.onNext(SHError.commonError(.weakSelfFailure))
                    return Observable.empty()
                }
                
                return self.createOrder(for: estate, errorRelay: errorRelay)
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    /// 주문 생성 처리
    private func createOrder(
        for estate: DetailEstate,
        errorRelay: PublishSubject<SHError>
    ) -> Observable<(OrderResponse, estateName: String)> {
        let orderRequest = OrderRequest(
            estate_id: estate.id,
            total_price: estate.reservationPrice
        )
        
        return apiClient
            .requestObservable(OrderEndpoint.order(body: orderRequest))
            .map { response in
                return (response, estateName: estate.title)
            }
            .catch { error -> Observable<(OrderResponse, estateName: String)> in
                errorRelay.onNext(SHError.from(error))
                return Observable.empty()
            }
            .do(onNext: { response, estateName in
                print("✅ 주문 생성 성공: \(response.order_id), 매물명: \(estateName)")
            })
    }
    
    /// 중개사 전화 버튼 처리
    private func handleBrokerCallButtonTapped(
        _ brokerCallButtonTapped: Observable<Void>
    ) -> Driver<Void> {
        return brokerCallButtonTapped
            .do(onNext: { _ in
                print("📞 중개사 전화 버튼 탭됨")
                // TODO: 전화 기능 구현
            })
            .asDriver(onErrorDriveWith: .empty())
    }
    
    /// 중개사 채팅 버튼 처리
    private func handleBrokerChatButtonTapped(
        _ brokerChatButtonTapped: Observable<Void>
    ) -> Driver<Void> {
        return brokerChatButtonTapped
            .do(onNext: { _ in
                print("💬 중개사 채팅 버튼 탭됨")
                // TODO: 채팅 기능 구현
            })
            .asDriver(onErrorDriveWith: .empty())
    }
    
    /// 유사한 매물 셀 처리
    private func handleSimilarCellTapped(
        _ similarCellTapped: Observable<Estate>
    ) -> Driver<Estate> {
        return similarCellTapped
            .do(onNext: { estate in
                print("🏠 유사한 매물 셀 탭됨: \(estate.title)")
                // TODO: 유사한 매물 상세 화면으로 이동
            })
            .asDriver(onErrorDriveWith: .empty())
    }
    
    /// 결제 검증 처리
    private func handlePaymentValidation(
        _ iamportResponse: Observable<PaymentIamportResponse>,
        errorRelay: PublishSubject<SHError>
    ) -> (success: PublishSubject<PaymentValidationResponse?>, error: PublishSubject<SHError?>) {
        
        let successRelay = PublishSubject<PaymentValidationResponse?>()
        let errorSubject = PublishSubject<SHError?>()
        
        iamportResponse
            .flatMapLatest { [weak self] response -> Observable<PaymentValidationResponse> in
                guard let self else {
                    errorSubject.onNext(SHError.commonError(.weakSelfFailure))
                    return Observable.empty()
                }
                
                return self.validatePaymentResult(response, errorRelay: errorSubject)
            }
            .subscribe(onNext: { validationResponse in
                successRelay.onNext(validationResponse)
            })
            .disposed(by: disposeBag)
        
        return (success: successRelay, error: errorSubject)
    }
    
    /// - 결제 결과 검증 및 API 호출
    private func validatePaymentResult(
        _ iamportResponse: PaymentIamportResponse,
        errorRelay: PublishSubject<SHError?>
    ) -> Observable<PaymentValidationResponse> {
        
        guard let imp_uid = iamportResponse.imp_uid,
              iamportResponse.success == true else {
            let error = SHError.networkError(.unknown(
                statusCode: nil,
                message: "결제에 실패헀습니다."
            ))
            errorRelay.onNext(error)
            return Observable.empty()
        }
        
        let validationRequest = PaymentValidationRequest(imp_uid: imp_uid)
        
        return apiClient
            .requestObservable(PaymentEndpoint.validation(body: validationRequest))
            .catch { error -> Observable<PaymentValidationResponse> in
                errorRelay.onNext(SHError.from(error))
                return Observable.empty()
            }
    }
    
    /// - 유사한 매물 로드
    private func loadSimilarEstates(errorRelay: PublishSubject<SHError>) {
        apiClient
            .requestObservable(EstateEndpoint.similarEstates)
            .map { (response: BaseEstateResponse) -> [Estate] in
                return response.data.map { $0.toDomain }
            }
            .catch { error -> Observable<[Estate]> in
                errorRelay.onNext(SHError.from(error))
                return Observable.just([])
            }
            .subscribe(onNext: { [weak self] estates in
                self?.similarEstatesRelay.onNext(estates)
            })
            .disposed(by: disposeBag)
    }
}
