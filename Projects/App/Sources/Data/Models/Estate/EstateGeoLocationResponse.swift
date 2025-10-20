//
//  EstateGeoLocationResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import Foundation

struct EstateGeoLocationResponse: Decodable {
    let data: [EstateGeoLocationDataResponse]
}

struct EstateGeoLocationDataResponse: Hashable, Decodable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let area: Double
    let floors: Int
    let geolocation: BaseGeolocationResponse
    let distance: Double
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let created_at: String
    let updated_at: String
}

//MARK: - Domain Conversion
extension EstateGeoLocationDataResponse {
    var toDomain: Estate {
        return Estate(
            id: self.estate_id,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            thumbnails: self.thumbnails,
            deposit: self.deposit,
            monthlyRent: self.monthly_rent,
            builtYear: self.built_year,
            area: Float(self.area),
            floors: self.floors,
            geolocation: Geolocation(
                lon: self.geolocation.longitude,
                lat: self.geolocation.latitude
            ),
            distance: self.distance,
            likeCount: self.like_count,
            isSafeEstate: self.is_safe_estate,
            isRecommended: self.is_recommended,
            createdAt: self.created_at.toISO8601Date() ?? Date(),
            updatedAt: self.updated_at.toISO8601Date() ?? Date()
        )
    }
}

