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
    /// - Parameter request: 주문 요청 데이터
    func createOrder(request: OrderRequest) -> Observable<OrderResponse> {
        return apiClient
            .requestObservable(OrderEndpoint.order(body: request))
    }

    /// - 결제 검증
    /// - Parameter request: 결제 검증 요청 데이터
    func validatePayment(request: PaymentValidationRequest) -> Observable<PaymentValidationResponse> {
        return apiClient
            .requestObservable(PaymentEndpoint.validation(body: request))
    }
}
