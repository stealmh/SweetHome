//
//  EstateMapRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateMapRepository의 구현체
final class EstateMapRepositoryImpl: EstateMapRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol

    // MARK: - Initialization
    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - EstateMapRepository Implementation

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
    ) -> Observable<[EstateGeoLocationDataResponse]> {
        let request = EstateGeoLocationRequest(
            category: category,
            longitude: longitude,
            latitude: latitude,
            maxDistance: maxDistance
        )

        return apiClient
            .requestObservable(EstateEndpoint.geoLocation(parameter: request))
            .map { (response: EstateGeoLocationResponse) -> [EstateGeoLocationDataResponse] in
                response.data
            }
    }
}
