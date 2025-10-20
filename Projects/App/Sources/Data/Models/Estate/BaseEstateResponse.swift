//
//  BaseEstateResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

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

extension BaseEstateDataResponse {
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
            area: self.area,
            floors: self.floors,
            geolocation: Geolocation(
                lon: self.geolocation.longitude,
                lat: self.geolocation.latitude
            ),
            distance: self.distance,
            likeCount: self.like_count,
            isSafeEstate: self.is_safe_estate,
            isRecommended: self.is_recommended,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/*
 {"data":[{"estate_id":"6822b4cd3013b77fe7469e1f","category":"아파트","title":"새싹 파노라마 뷰\n역세권 아파트","introduction":"한강과 북한산 조망이 가능한 프리미엄 아파트","thumbnails":["/data/estates/example_1_1747104960999.jpg","/data/estates/example_2_1747104961017.jpg","/data/estates/example_3_1747104961024.jpg"],"deposit":8500000000,"monthly_rent":4500000,"built_year":"2022-05-15","area":84.5,"floors":25,"geolocation":{"longitude":127.043553,"latitude":37.650158},"like_count":1,"is_safe_estate":true,"is_recommended":true,"created_at":"2025-05-13T02:56:13.816Z","updated_at":"2025-05-31T05:50:47.862Z"},{"estate_id":"6822b5fd3013b77fe7469e2c","category":"오피스텔","title":"펜트하우스 오피스텔","introduction":"최고층 프라이빗 테라스 포함","thumbnails":["/data/estates/francesca-tosolini-w1RE0lBbREo-unsplash_1747105244716.jpg","/data/estates/michael-oxendine-GHCVUtBECuY-unsplash_1747105244880.jpg","/data/estates/spacejoy-umAXneH4GhA-unsplash_1747105245035.jpg"],"deposit":7200000000,"monthly_rent":3800000,"built_year":"2021-11-20","area":76.2,"floors":32,"geolocation":{"longitude":127.043553,"latitude":37.650158},"like_count":1,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T03:01:17.826Z","updated_at":"2025-06-03T09:22:54.324Z"},{"estate_id":"6822b6963013b77fe7469e39","category":"빌라","title":"창동 프리미엄 타운하우스","introduction":"정원과 테라스를 갖춘 고급 주택","thumbnails":["/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg","/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],"deposit":6500000000,"monthly_rent":3200000,"built_year":"2023-02-10","area":92.4,"floors":4,"geolocation":{"longitude":127.048421,"latitude":37.657372},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T03:03:50.844Z","updated_at":"2025-07-31T08:25:22.782Z"}]}
 
 
 */
