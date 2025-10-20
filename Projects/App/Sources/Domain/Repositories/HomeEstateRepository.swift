//
//  HomeEstateRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 홈 화면의 매물 관련 데이터 접근을 추상화하는 Repository
public protocol HomeEstateRepository {
    /// - 오늘의 매물 목록 조회
    func fetchTodayEstates() -> Observable<[Estate]>

    /// - 인기 매물 목록 조회
    func fetchHotEstates() -> Observable<[Estate]>

    /// - 오늘의 부동산 토픽 조회
    func fetchTopics() -> Observable<[EstateTopic]>
}
