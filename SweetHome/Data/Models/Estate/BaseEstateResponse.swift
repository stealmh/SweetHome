//
//  BaseEstateResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

/// - 부동산에서 조회되는 매물들의 기본적인 형태의 DTO
struct BaseEstateResponse: Decodable {
    let data: [BaseEstateDataResponse]
}

struct BaseEstateDataResponse: Decodable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    /// - format: 2020-01-04
    let built_year: String
    let area: Float
    let floors: Int
    let geolocation: BaseGeolocationResponse
    let distance: Double?
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    /// - format: 9999-10-19T03:05:03.422Z
    let created_at: String
    /// - format: 9999-10-19T03:05:03.422Z
    let updated_at: String
}

/*
 {
 "data": [
 {
 "estate_id": "670bcd66539a670e42b2a3d8",
 "category": "아파트",
 "title": "한강 파노라 뷰\n역세권 아파트",
 "introduction": "풀옵션, 즉시 입주 가능!",
 "thumbnails": [
 "/data/estates/thumb_1712739634962.png"
 ],
 "deposit": 10000000,
 "monthly_rent": 500000,
 "built_year": "2020-01-04",
 "area": 25.5,
 "floors": 1,
 "geolocation": {
 "longitude": 126.886557,
 "latitude": 37.51775
 },
 "distance": 75.42775857964551,
 "like_count": 5,
 "is_safe_estate": false,
 "is_recommended": false,
 "created_at": "9999-10-19T03:05:03.422Z",
 "updated_at": "9999-10-20T04:10:10.123Z"
 }
 ]
 }
 
 
 
 */
