//
//  EstateDetailUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateDetailUseCase의 구현체
final class EstateDetailUseCaseImpl: EstateDetailUseCase {

    // MARK: - Dependencies
    private let repository: EstateDetailRepository

    // MARK: - Initialization
    init(repository: EstateDetailRepository) {
        self.repository = repository
    }

    // MARK: - EstateDetailUseCase Implementation

    /// - 매물 상세정보 조회
    /// - Parameter estateID: 매물 ID
    func fetchEstateDetail(estateID: String) -> Observable<DetailEstate> {
        return repository.fetchEstateDetail(estateID: estateID)
    }

    /// - 좋아요 토글 (낙관적 업데이트 포함)
    /// - Parameter currentDetail: 현재 매물 상세정보
    /// - Returns: (낙관적 업데이트된 DetailEstate, API 호출 결과)
    func toggleFavorite(currentDetail: DetailEstate) -> (optimistic: DetailEstate, apiResult: Observable<Void>) {
        let newLikeStatus = !currentDetail.isLiked
        let optimisticDetail = createOptimisticDetail(from: currentDetail, newLikeStatus: newLikeStatus)

        let apiResult = repository.updateLikeStatus(estateID: currentDetail.id, likeStatus: newLikeStatus)

        return (optimistic: optimisticDetail, apiResult: apiResult)
    }

    /// - 유사한 매물 목록 조회
    func fetchSimilarEstates() -> Observable<[Estate]> {
        return repository.fetchSimilarEstates()
    }

    /// - 예약 주문 생성
    /// - Parameter estate: 매물 상세정보
    /// - Returns: (주문 응답, 매물명)
    func createReservation(estate: DetailEstate) -> Observable<(OrderResponse, estateName: String)> {
        let orderRequest = OrderRequest(
            estate_id: estate.id,
            total_price: estate.reservationPrice
        )

        return repository.createOrder(request: orderRequest)
            .map { response in
                return (response, estateName: estate.title)
            }
    }

    /// - 결제 검증
    /// - Parameter iamportResponse: 아임포트 결제 응답
    func validatePayment(iamportResponse: PaymentIamportResponse) -> Observable<PaymentValidationResponse> {
        guard let imp_uid = iamportResponse.imp_uid,
              iamportResponse.success == true else {
            return Observable.error(SHError.networkError(.unknown(
                statusCode: nil,
                message: "결제에 실패했습니다."
            )))
        }

        let validationRequest = PaymentValidationRequest(imp_uid: imp_uid)
        return repository.validatePayment(request: validationRequest)
    }

    // MARK: - Private Methods

    /// - 낙관적 업데이트를 위한 DetailEstate 생성
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
}
