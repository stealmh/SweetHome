//
//  EstateMapRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 지도 기반 매물 관련 데이터 접근을 추상화하는 Repository
protocol EstateMapRepository {
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
}
