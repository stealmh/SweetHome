//
//  EstateDetailRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateDetailRepository의 구현체
final class EstateDetailRepositoryImpl: EstateDetailRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol

    // MARK: - Initialization
    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - EstateDetailRepository Implementation

    /// - 매물 상세정보 조회
    /// - Parameter estateID: 매물 ID
    func fetchEstateDetail(estateID: String) -> Observable<DetailEstate> {
        return apiClient
            .requestObservable(EstateEndpoint.detail(id: estateID))
            .map { (response: DetailEstateResponse) -> DetailEstate in
                response.toDomain
            }
    }

    /// - 좋아요 상태 변경
    /// - Parameters:
    ///   - estateID: 매물 ID
    ///   - likeStatus: 좋아요 상태
    func updateLikeStatus(estateID: String, likeStatus: Bool) -> Observable<Void> {
        let requestBody = DetailEstateLikeStatus(like_status: likeStatus)
        return apiClient
            .requestObservable(EstateEndpoint.like(id: estateID, body: requestBody))
            .map { (_: DetailEstateLikeStatus) in () }
    }

    /// - 유사한 매물 목록 조회
    func fetchSimilarEstates() -> Observable<[Estate]> {
        return apiClient
            .requestObservable(EstateEndpoint.similarEstates)
            .map { (response: BaseEstateResponse) -> [Estate] in
                response.data.map { $0.toDomain }
            }
    }

    /// - 주문 생성
    /// - Parameters:
    ///   - estateId: 매물 ID
    ///   - totalPrice: 총 가격
    /// - Returns: 주문 정보
    func createOrder(estateId: String, totalPrice: Int) -> Observable<Order> {
        let request = OrderRequest(estate_id: estateId, total_price: totalPrice)
        return apiClient
            .requestObservable(OrderEndpoint.order(body: request))
            .map { (response: OrderResponse) -> Order in
                Order(
                    orderId: response.order_id,
                    orderCode: response.order_code,
                    totalPrice: response.total_price,
                    createdAt: response.createdAt.toISO8601Date() ?? Date(),
                    updatedAt: response.updatedAt.toISO8601Date() ?? Date()
                )
            }
    }

    /// - 결제 검증
    /// - Parameter impUid: 아임포트 결제 고유 ID
    /// - Returns: 결제 검증 결과
    func validatePayment(impUid: String) -> Observable<PaymentValidation> {
        let request = PaymentValidationRequest(imp_uid: impUid)
        return apiClient
            .requestObservable(PaymentEndpoint.validation(body: request))
            .map { (response: PaymentValidationResponse) -> PaymentValidation in
                PaymentValidation(
                    paymentId: response.payment_id,
                    orderItem: OrderItem(
                        orderId: response.order_item.order_id,
                        orderCode: response.order_item.order_code,
                        estate: OrderEstate(
                            id: response.order_item.estate.id,
                            category: response.order_item.estate.category,
                            title: response.order_item.estate.title,
                            introduction: response.order_item.estate.introduction,
                            thumbnails: response.order_item.estate.thumbnails,
                            deposit: response.order_item.estate.deposit,
                            monthlyRent: response.order_item.estate.monthly_rent,
                            builtYear: response.order_item.estate.built_year,
                            area: response.order_item.estate.area,
                            floors: response.order_item.estate.floors,
                            geolocation: Geolocation(
                                lon: response.order_item.estate.geolocation.longitude,
                                lat: response.order_item.estate.geolocation.latitude
                            ),
                            createdAt: response.order_item.estate.createdAt.toISO8601Date() ?? Date(),
                            updatedAt: response.order_item.estate.updatedAt.toISO8601Date() ?? Date()
                        ),
                        paidAt: response.order_item.paidAt.toISO8601Date() ?? Date(),
                        createdAt: response.order_item.createdAt.toISO8601Date() ?? Date(),
                        updatedAt: response.order_item.updatedAt.toISO8601Date() ?? Date()
                    ),
                    createdAt: response.createdAt.toISO8601Date() ?? Date(),
                    updatedAt: response.updatedAt.toISO8601Date() ?? Date()
                )
            }
    }
}
