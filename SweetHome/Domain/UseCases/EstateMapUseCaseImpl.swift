//
//  EstateMapUseCaseImpl.swift
//  SweetHome
//
//  Created by 김민호 on 10/15/25.
//

import Foundation
import RxSwift

/// - EstateMapUseCase의 구현체
final class EstateMapUseCaseImpl: EstateMapUseCase {

    // MARK: - Dependencies
    private let repository: EstateMapRepository

    // MARK: - Initialization
    init(repository: EstateMapRepository) {
        self.repository = repository
    }

    // MARK: - EstateMapUseCase Implementation

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
        return repository.fetchEstatesByLocation(
            category: category,
            latitude: latitude,
            longitude: longitude,
            maxDistance: maxDistance
        )
    }

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
    ) -> [EstateGeoLocationDataResponse] {
        guard hasActiveFilters(areaFilter: areaFilter, monthlyPriceFilter: monthlyPriceFilter, depositFilter: depositFilter) else {
            return estates
        }

        return estates.filter { estate in
            return passesAreaFilter(estate, filter: areaFilter) &&
                   passesMonthlyPriceFilter(estate, filter: monthlyPriceFilter) &&
                   passesDepositFilter(estate, filter: depositFilter)
        }
    }

    // MARK: - Private Methods

    /// - 활성화된 필터가 있는지 확인
    private func hasActiveFilters(
        areaFilter: (Float, Float)?,
        monthlyPriceFilter: (Float, Float)?,
        depositFilter: (Float, Float)?
    ) -> Bool {
        return areaFilter != nil || monthlyPriceFilter != nil || depositFilter != nil
    }

    /// - 면적 필터 통과 여부
    private func passesAreaFilter(_ estate: EstateGeoLocationDataResponse, filter: (Float, Float)?) -> Bool {
        guard let areaFilter = filter else { return true }

        let estateArea = Float(estate.area)
        let estateAreaPyeong = estateArea * 0.3025  // m² to 평 conversion

        return estateAreaPyeong >= areaFilter.0 && estateAreaPyeong <= areaFilter.1
    }

    /// - 월세 필터 통과 여부
    private func passesMonthlyPriceFilter(_ estate: EstateGeoLocationDataResponse, filter: (Float, Float)?) -> Bool {
        guard let priceFilter = filter else { return true }

        // 서버에서 1원 단위로 전송되므로 만원 단위로 변환
        let monthlyPriceManWon = Float(estate.monthly_rent) / 10000

        // 최대값(200만원)을 선택했을 때는 그보다 큰 값도 포함
        if priceFilter.1 >= 200 {
            return monthlyPriceManWon >= priceFilter.0
        } else {
            return monthlyPriceManWon >= priceFilter.0 && monthlyPriceManWon <= priceFilter.1
        }
    }

    /// - 보증금 필터 통과 여부
    private func passesDepositFilter(_ estate: EstateGeoLocationDataResponse, filter: (Float, Float)?) -> Bool {
        guard let depositFilter = filter else { return true }

        // 서버에서 1원 단위로 전송되므로 만원 단위로 변환
        let depositManWon = Float(estate.deposit) / 10000

        // 최대값(1억 = 10000만원)을 선택했을 때는 그보다 큰 값(예: 5억)도 포함
        if depositFilter.1 >= 10000 {
            return depositManWon >= depositFilter.0
        } else {
            return depositManWon >= depositFilter.0 && depositManWon <= depositFilter.1
        }
    }
}
