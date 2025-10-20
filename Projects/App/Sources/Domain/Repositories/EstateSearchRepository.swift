//
//  EstateSearchRepository.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 매물 검색 관련 데이터 접근을 추상화하는 Repository
public protocol EstateSearchRepository {
    /// - 매물 검색
    /// - Parameter query: 검색어
    func searchEstates(query: String) -> Observable<[Estate]>
}
