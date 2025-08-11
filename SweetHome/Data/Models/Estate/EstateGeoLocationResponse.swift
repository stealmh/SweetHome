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

struct EstateGeoLocationDataResponse: Decodable {
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

