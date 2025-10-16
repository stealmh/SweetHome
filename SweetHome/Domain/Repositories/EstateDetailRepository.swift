//
//  EstateDetailRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 매물 상세 관련 데이터 접근을 추상화하는 Repository
public protocol EstateDetailRepository {
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
    /// - Parameters:
    ///   - estateId: 매물 ID
    ///   - totalPrice: 총 가격
    /// - Returns: 주문 정보
    func createOrder(estateId: String, totalPrice: Int) -> Observable<Order>

    /// - 결제 검증
    /// - Parameter impUid: 아임포트 결제 고유 ID
    /// - Returns: 결제 검증 결과
    func validatePayment(impUid: String) -> Observable<PaymentValidation>
}
