//
//  EstateSearchUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateSearchUseCase의 구현체
final class EstateSearchUseCaseImpl: EstateSearchUseCase {

    // MARK: - Dependencies
    private let repository: EstateSearchRepository

    // MARK: - Initialization
    init(repository: EstateSearchRepository) {
        self.repository = repository
    }

    // MARK: - EstateSearchUseCase Implementation

    /// - 매물 검색
    /// - Parameter query: 검색어
    func searchEstates(query: String) -> Observable<[Estate]> {
        return repository.searchEstates(query: query)
    }
}
