//
//  EstateError.swift
//  SweetHome
//
//  Created by 김민호 on 9/1/25.
//

import Foundation

enum EstateError {
    /// - 검색 조건에 맞는 매물이 없을 때
    case noEstatesFound
    /// - 위치 정보가 유효하지 않을 때
    case invalidLocation
    /// - 필터 범위가 올바르지 않을 때
    case filterRangeInvalid
    /// - 지도 로딩이 실패했을 때
    case mapLoadFailed
    /// - 위치 기반 매물 검색이 실패했을 때
    case geoLocationFailed
    /// - 매물 상세 정보를 찾을 수 없을 때
    case estateDetailNotFound(String)
}

extension EstateError {
    var message: String {
        switch self {
        case .noEstatesFound:
            return "해당 지역에 매물이 없습니다."
        case .invalidLocation:
            return "유효하지 않은 위치입니다."
        case .filterRangeInvalid:
            return "필터 범위가 올바르지 않습니다."
        case .mapLoadFailed:
            return "지도를 불러오는데 실패했습니다."
        case .geoLocationFailed:
            return "위치 기반 매물 검색에 실패했습니다."
        case .estateDetailNotFound(let estateId):
            return "매물 정보(\(estateId))를 찾을 수 없습니다."
        }
    }
    
    var displayType: ErrorDisplayType {
        switch self {
        case .noEstatesFound:
            return .componentText
        case .invalidLocation, .filterRangeInvalid, .mapLoadFailed, .geoLocationFailed, .estateDetailNotFound:
            return .toast
        }
    }
}