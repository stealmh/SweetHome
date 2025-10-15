//
//  EstateSearchRepositoryImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateSearchRepository의 구현체
final class EstateSearchRepositoryImpl: EstateSearchRepository {

    // MARK: - Dependencies
    private let apiClient: ApiClientProtocol

    // MARK: - Initialization
    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - EstateSearchRepository Implementation

    /// - 매물 검색
    /// - Parameter query: 검색어
    func searchEstates(query: String) -> Observable<[Estate]> {
        /// - TODO: 실제 API 호출로 교체 필요
        /// - 현재는 Mock 데이터 필터링으로 대체
        let mockResults = Estate.searchResultMock.filter { estate in
            estate.title.lowercased().contains(query.lowercased()) ||
            estate.category.lowercased().contains(query.lowercased()) ||
            estate.introduction.lowercased().contains(query.lowercased())
        }

        return Observable.just(mockResults.isEmpty ? Estate.searchResultMock : mockResults)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
    }
}
