//
//  EstateSearchUseCase.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - 매물 검색 관련 비즈니스 로직을 추상화하는 UseCase
public protocol EstateSearchUseCase {
    /// - 매물 검색
    /// - Parameter query: 검색어
    func searchEstates(query: String) -> Observable<[Estate]>
}
