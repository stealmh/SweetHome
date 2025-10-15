//
//  EstateMapUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 지도 기반 매물 관련 비즈니스 로직을 추상화하는 UseCase
protocol EstateMapUseCase {
    /// - 위치 기반 매물 목록 조회
    /// - Parameters:
    ///   - category: 매물 카테고리
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - maxDistance: 최대 거리 (미터)
    func fetchEstatesByLocation(
        category: String,
        latitude: String,
        longitude: String,
        maxDistance: Int
    ) -> Observable<[EstateGeoLocationDataResponse]>

    /// - 매물 필터링 적용
    /// - Parameters:
    ///   - estates: 필터링할 매물 목록
    ///   - areaFilter: 면적 필터 (평, 최소-최대)
    ///   - monthlyPriceFilter: 월세 필터 (만원, 최소-최대)
    ///   - depositFilter: 보증금 필터 (만원, 최소-최대)
    func filterEstates(
        _ estates: [EstateGeoLocationDataResponse],
        areaFilter: (Float, Float)?,
        monthlyPriceFilter: (Float, Float)?,
        depositFilter: (Float, Float)?
    ) -> [EstateGeoLocationDataResponse]
}
