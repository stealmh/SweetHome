//
//  EstateDetailUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 매물 상세 관련 비즈니스 로직을 추상화하는 UseCase
protocol EstateDetailUseCase {
    /// - 매물 상세정보 조회
    /// - Parameter estateID: 매물 ID
    func fetchEstateDetail(estateID: String) -> Observable<DetailEstate>

    /// - 좋아요 토글 (낙관적 업데이트 포함)
    /// - Parameter currentDetail: 현재 매물 상세정보
    /// - Returns: (낙관적 업데이트된 DetailEstate, API 호출 결과)
    func toggleFavorite(currentDetail: DetailEstate) -> (optimistic: DetailEstate, apiResult: Observable<Void>)

    /// - 유사한 매물 목록 조회
    func fetchSimilarEstates() -> Observable<[Estate]>

    /// - 예약 주문 생성
    /// - Parameter estate: 매물 상세정보
    /// - Returns: (주문 응답, 매물명)
    func createReservation(estate: DetailEstate) -> Observable<(OrderResponse, estateName: String)>

    /// - 결제 검증
    /// - Parameter iamportResponse: 아임포트 결제 응답
    func validatePayment(iamportResponse: PaymentIamportResponse) -> Observable<PaymentValidationResponse>
}
