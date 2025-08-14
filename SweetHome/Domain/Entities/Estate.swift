//
//  Estate.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

// MARK: - Domain Models (Entity)
struct Estate: Hashable {
    let id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthlyRent: Int
    let builtYear: String
    let area: Float
    let floors: Int
    let geolocation: Geolocation
    let distance: Double?
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let createdAt: Date
    let updatedAt: Date
}

extension Estate {
    /// 월세 표시용 문자열
    var rentDisplayText: String {
        if self.monthlyRent == 0 {
            return "전세 \(deposit.formattedPrice)"
        } else {
            return "월세 \(deposit.formattedPrice)/\(monthlyRent.formattedPrice)"
        }
    }
}


struct Geolocation: Hashable {
    let lon: Double
    let lat: Double
}
