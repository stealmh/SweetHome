//
//  HomeEstateRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - HomeEstateRepository의 구현체
final class HomeEstateRepositoryImpl: HomeEstateRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol

    // MARK: - Initialization
    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - HomeEstateRepository Implementation

    /// - 오늘의 매물 목록 조회
    func fetchTodayEstates() -> Observable<[Estate]> {
        return apiClient
            .requestObservable(EstateEndpoint.todayEstates)
            .map { (response: BaseEstateResponse) -> [Estate] in
                response.data.map { $0.toDomain }
            }
    }

    /// - 인기 매물 목록 조회
    func fetchHotEstates() -> Observable<[Estate]> {
        return apiClient
            .requestObservable(EstateEndpoint.hotEstates)
            .map { (response: BaseEstateResponse) -> [Estate] in
                response.data.map { $0.toDomain }
            }
    }

    /// - 오늘의 부동산 토픽 조회
    func fetchTopics() -> Observable<[EstateTopic]> {
        return apiClient
            .requestObservable(EstateEndpoint.topics)
            .map { (response: EstateTopicResponse) -> [EstateTopic] in
                response.data.map { $0.toDomain }
            }
    }
}
