//
//  HomeUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - HomeUseCase의 구현체
public final class HomeUseCaseImpl: HomeUseCase {

    // MARK: - Dependencies
    private let repository: HomeEstateRepository

    // MARK: - Initialization
    public init(repository: HomeEstateRepository) {
        self.repository = repository
    }

    // MARK: - HomeUseCase Implementation

    /// - 오늘의 매물 목록 조회
    public func fetchTodayEstates() -> Observable<[Estate]> {
        return repository.fetchTodayEstates()
    }

    /// - 인기 매물 목록 조회
    public func fetchHotEstates() -> Observable<[Estate]> {
        return repository.fetchHotEstates()
    }

    /// - 오늘의 부동산 토픽 조회
    public func fetchTopics() -> Observable<[EstateTopic]> {
        return repository.fetchTopics()
    }
}
