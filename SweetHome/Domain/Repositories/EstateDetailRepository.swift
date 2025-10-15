//
//  EstateDetailRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 매물 상세 관련 데이터 접근을 추상화하는 Repository
protocol EstateDetailRepository {
    /// - 매물 상세정보 조회
    /// - Parameter estateID: 매물 ID
    func fetchEstateDetail(estateID: String) -> Observable<DetailEstate>

    /// - 좋아요 상태 변경
    /// - Parameters:
    ///   - estateID: 매물 ID
    ///   - likeStatus: 좋아요 상태
    func updateLikeStatus(estateID: String, likeStatus: Bool) -> Observable<Void>

    /// - 유사한 매물 목록 조회
    func fetchSimilarEstates() -> Observable<[Estate]>

    /// - 주문 생성
    /// - Parameter request: 주문 요청 데이터
    func createOrder(request: OrderRequest) -> Observable<OrderResponse>

    /// - 결제 검증
    /// - Parameter request: 결제 검증 요청 데이터
    func validatePayment(request: PaymentValidationRequest) -> Observable<PaymentValidationResponse>
}
