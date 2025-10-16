//
//  EstateDetailUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateDetailUseCase의 구현체
public final class EstateDetailUseCaseImpl: EstateDetailUseCase {

    // MARK: - Dependencies
    private let repository: EstateDetailRepository

    // MARK: - Initialization
    public init(repository: EstateDetailRepository) {
        self.repository = repository
    }

    // MARK: - EstateDetailUseCase Implementation

    /// - 매물 상세정보 조회
    /// - Parameter estateID: 매물 ID
    public func fetchEstateDetail(estateID: String) -> Observable<DetailEstate> {
        return repository.fetchEstateDetail(estateID: estateID)
    }

    /// - 좋아요 토글 (낙관적 업데이트 포함)
    /// - Parameter currentDetail: 현재 매물 상세정보
    /// - Returns: (낙관적 업데이트된 DetailEstate, API 호출 결과)
    public func toggleFavorite(currentDetail: DetailEstate) -> (optimistic: DetailEstate, apiResult: Observable<Void>) {
        let newLikeStatus = !currentDetail.isLiked
        let optimisticDetail = createOptimisticDetail(from: currentDetail, newLikeStatus: newLikeStatus)

        let apiResult = repository.updateLikeStatus(estateID: currentDetail.id, likeStatus: newLikeStatus)

        return (optimistic: optimisticDetail, apiResult: apiResult)
    }

    /// - 유사한 매물 목록 조회
    public func fetchSimilarEstates() -> Observable<[Estate]> {
        return repository.fetchSimilarEstates()
    }

    /// - 예약 주문 생성
    /// - Parameter estate: 매물 상세정보
    /// - Returns: (주문 정보, 매물명)
    public func createReservation(estate: DetailEstate) -> Observable<(Order, estateName: String)> {
        return repository.createOrder(estateId: estate.id, totalPrice: estate.reservationPrice)
            .map { order in
                return (order, estateName: estate.title)
            }
    }

    /// - 결제 검증
    /// - Parameter impUid: 아임포트 결제 고유 ID
    /// - Returns: 결제 검증 결과
    public func validatePayment(impUid: String) -> Observable<PaymentValidation> {
        return repository.validatePayment(impUid: impUid)
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
