//
//  Estate.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

// MARK: - Domain Models (Entity)
public struct Estate: Hashable {
    public let id: String
    public let category: String
    public let title: String
    public let introduction: String
    public let thumbnails: [String]
    public let deposit: Int
    public let monthlyRent: Int
    public let builtYear: String
    public let area: Float
    public let floors: Int
    public let geolocation: Geolocation
    public let distance: Double?
    public let likeCount: Int
    public let isSafeEstate: Bool
    public let isRecommended: Bool
    public let createdAt: Date
    public let updatedAt: Date
}

public extension Estate {
    /// 월세 표시용 문자열
    var rentDisplayText: String {
        if self.monthlyRent == 0 {
            return "전세 \(deposit.formattedPrice)"
        } else {
            return "보증금 \(deposit.formattedPrice), 월세 \(monthlyRent.formattedPrice)"
        }
    }
}

public extension Estate {
    static let topEstateMock: [Estate] = [
        Estate(
            id: "6822b4cd3013b77fe7469e1f",
            category: "아파트",
            title: "신반포역 도보3분\n역세권 아파트",
            introduction: "반포한강공원, 종합운동장이 위치해 산책하기 좋은 곳",
            thumbnails: [
                "/data/estates/example_1_1747104960999.jpg",
                "/data/estates/example_2_1747104961017.jpg",
                "/data/estates/example_3_1747104961024.jpg"
            ],
            deposit: 8500000000,
            monthlyRent: 4500000,
            builtYear: "2022-05-15",
            area: 84.5,
            floors: 25,
            geolocation: Geolocation(lon: 127.043553, lat: 37.650158),
            distance: nil,
            likeCount: 1,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(timeIntervalSince1970: 1715559373.816),
            updatedAt: Date(timeIntervalSince1970: 1723204712.503)
        ),
        Estate(
            id: "6822b5fd3013b77fe7469e2c",
            category: "오피스텔",
            title: "펜트하우스 오피스텔",
            introduction: "최고층 프라이빗 테라스 포함",
            thumbnails: [
                "/data/estates/francesca-tosolini-w1RE0lBbREo-unsplash_1747105244716.jpg",
                "/data/estates/michael-oxendine-GHCVUtBECuY-unsplash_1747105244880.jpg",
                "/data/estates/spacejoy-umAXneH4GhA-unsplash_1747105245035.jpg"
            ],
            deposit: 7200000000,
            monthlyRent: 3800000,
            builtYear: "2021-11-20",
            area: 76.2,
            floors: 32,
            geolocation: Geolocation(lon: 127.043553, lat: 37.650158),
            distance: nil,
            likeCount: 1,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715559677.826),
            updatedAt: Date(timeIntervalSince1970: 1726146181.698)
        ),
        Estate(
            id: "6822b6963013b77fe7469e39",
            category: "빌라",
            title: "창동 프리미엄 타운하우스",
            introduction: "정원과 테라스를 갖춘 고급 주택",
            thumbnails: [
                "/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg",
                "/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"
            ],
            deposit: 6500000000,
            monthlyRent: 3200000,
            builtYear: "2023-02-10",
            area: 92.4,
            floors: 4,
            geolocation: Geolocation(lon: 127.048421, lat: 37.657372),
            distance: nil,
            likeCount: 0,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715559830.844),
            updatedAt: Date(timeIntervalSince1970: 1722410722.782)
        )
    ]

    static let searchResultMock: [Estate] = [
        Estate(
            id: "search_result_1",
            category: "원룸",
            title: "신촌역 도보 2분 깔끔한 원룸",
            introduction: "풀옵션, 세탁기, 냉장고 포함",
            thumbnails: [
                "/data/estates/house6_1747146288315.png",
                "/data/estates/house7_1747146288375.png"
            ],
            deposit: 50000000,
            monthlyRent: 400000,
            builtYear: "2019-03-15",
            area: 16.5,
            floors: 4,
            geolocation: Geolocation(lon: 126.936893, lat: 37.558347),
            distance: nil,
            likeCount: 8,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715559373.816),
            updatedAt: Date(timeIntervalSince1970: 1723204712.503)
        ),
        Estate(
            id: "search_result_2",
            category: "투룸",
            title: "홍대입구역 5분거리 넓은 투룸",
            introduction: "분리형 원룸, 베란다 있음",
            thumbnails: [
                "/data/estates/house8_1747146288397.png",
                "/data/estates/house9_1747146288414.png"
            ],
            deposit: 100000000,
            monthlyRent: 800000,
            builtYear: "2021-06-20",
            area: 26.4,
            floors: 8,
            geolocation: Geolocation(lon: 126.924191, lat: 37.556701),
            distance: nil,
            likeCount: 23,
            isSafeEstate: false,
            isRecommended: true,
            createdAt: Date(timeIntervalSince1970: 1715559677.826),
            updatedAt: Date(timeIntervalSince1970: 1726146181.698)
        ),
        Estate(
            id: "search_result_3",
            category: "오피스텔",
            title: "강남역 도보 10분 고층 오피스텔",
            introduction: "24시간 보안, 피트니스 센터 완비",
            thumbnails: [
                "/data/estates/house10_1747146288434.png",
                "/data/estates/house11_1747146326584.png"
            ],
            deposit: 200000000,
            monthlyRent: 1200000,
            builtYear: "2020-09-10",
            area: 32.8,
            floors: 18,
            geolocation: Geolocation(lon: 127.027926, lat: 37.497175),
            distance: nil,
            likeCount: 45,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(timeIntervalSince1970: 1715559830.844),
            updatedAt: Date(timeIntervalSince1970: 1722410722.782)
        ),
        Estate(
            id: "search_result_4",
            category: "아파트",
            title: "잠실 신축 아파트 남향 3룸",
            introduction: "한강뷰, 대형 베란다, 주차 2대 가능",
            thumbnails: [
                "/data/estates/house12_1747146326628.png",
                "/data/estates/house13_1747146326641.png"
            ],
            deposit: 1500000000,
            monthlyRent: 0,
            builtYear: "2023-12-01",
            area: 84.2,
            floors: 15,
            geolocation: Geolocation(lon: 127.082375, lat: 37.513847),
            distance: nil,
            likeCount: 67,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604998.696),
            updatedAt: Date(timeIntervalSince1970: 1715604998.696)
        ),
        Estate(
            id: "search_result_5",
            category: "빌라",
            title: "성수동 감성 빌라 루프탑 포함",
            introduction: "개별 테라스, 펜트하우스 느낌",
            thumbnails: [
                "/data/estates/house14_1747146326667.png",
                "/data/estates/house15_1747146326683.png"
            ],
            deposit: 80000000,
            monthlyRent: 600000,
            builtYear: "2018-05-30",
            area: 42.1,
            floors: 3,
            geolocation: Geolocation(lon: 127.044927, lat: 37.544582),
            distance: nil,
            likeCount: 12,
            isSafeEstate: false,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715582564.741),
            updatedAt: Date(timeIntervalSince1970: 1715582564.741)
        ),
        Estate(
            id: "search_result_6",
            category: "원룸",
            title: "이대역 초근거리 깨끗한 신축",
            introduction: "엘리베이터, 택배함, CCTV 완비",
            thumbnails: [
                "/data/estates/house16_1747146354975.png",
                "/data/estates/house17_1747146355023.png"
            ],
            deposit: 30000000,
            monthlyRent: 350000,
            builtYear: "2022-11-15",
            area: 14.2,
            floors: 2,
            geolocation: Geolocation(lon: 126.946026, lat: 37.556785),
            distance: nil,
            likeCount: 6,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604755.336),
            updatedAt: Date(timeIntervalSince1970: 1715604755.336)
        ),
        Estate(
            id: "search_result_7",
            category: "투룸",
            title: "건대입구역 3분 분리형 투룸",
            introduction: "방 2개, 거실 분리, 옥상 이용 가능",
            thumbnails: [
                "/data/estates/house2_1747146245212.png",
                "/data/estates/house4_1747146245264.png"
            ],
            deposit: 70000000,
            monthlyRent: 500000,
            builtYear: "2020-02-28",
            area: 29.7,
            floors: 6,
            geolocation: Geolocation(lon: 127.070171, lat: 37.540503),
            distance: nil,
            likeCount: 18,
            isSafeEstate: false,
            isRecommended: true,
            createdAt: Date(timeIntervalSince1970: 1715604852.860),
            updatedAt: Date(timeIntervalSince1970: 1715604852.860)
        ),
        Estate(
            id: "search_result_8",
            category: "오피스텔",
            title: "판교 테크노밸리 신축 오피스텔",
            introduction: "업무용 최적, 주차 편리, 카페거리 인근",
            thumbnails: [
                "/data/estates/example_1_1747104960999.jpg",
                "/data/estates/example_2_1747104961017.jpg"
            ],
            deposit: 300000000,
            monthlyRent: 0,
            builtYear: "2023-08-20",
            area: 45.6,
            floors: 22,
            geolocation: Geolocation(lon: 127.111837, lat: 37.395225),
            distance: nil,
            likeCount: 31,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604549.963),
            updatedAt: Date(timeIntervalSince1970: 1715604549.963)
        )
    ]

    static let hotEstateMock: [Estate] = [
        Estate(
            id: "68235da61a1032c4e2d9c3be",
            category: "빌라",
            title: "공원 근처 쾌적한 환경",
            introduction: "24시간 보안 시스템!",
            thumbnails: [
                "/data/estates/house9_1747146288414.png",
                "/data/estates/house8_1747146288397.png",
                "/data/estates/house11_1747146326584.png"
            ],
            deposit: 200000000,
            monthlyRent: 600000,
            builtYear: "2011-05-22",
            area: 21.3,
            floors: 12,
            geolocation: Geolocation(lon: 127.063002, lat: 37.616007),
            distance: nil,
            likeCount: 0,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604998.696),
            updatedAt: Date(timeIntervalSince1970: 1715604998.696)
        ),
        Estate(
            id: "6822fefc1a1032c4e2d9b414",
            category: "아파트",
            title: "푸르지오 아파트",
            introduction: "짐만 오면 OK! 풀옵션 + 채광 좋은 신축 남향",
            thumbnails: [
                "/data/estates/roberto-nickson-rEJxpBskj3Q-unsplash_1747107238994.jpg",
                "/data/estates/michael-oxendine-BfkTFeysp34-unsplash_1747107239103.jpg",
                "/data/estates/spacejoy-nEtpvJjnPVo-unsplash_1747107239209.jpg"
            ],
            deposit: 150000000,
            monthlyRent: 3000000,
            builtYear: "2022-05-15",
            area: 84.0,
            floors: 9,
            geolocation: Geolocation(lon: 127.05191994611108, lat: 37.653585669845036),
            distance: nil,
            likeCount: 0,
            isSafeEstate: true,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715582564.741),
            updatedAt: Date(timeIntervalSince1970: 1715582564.741)
        ),
        Estate(
            id: "68235cb31a1032c4e2d9bf40",
            category: "아파트",
            title: "헬스장과 수영장이 있는 고급 주택",
            introduction: "전기차 충전소 설치!",
            thumbnails: [
                "/data/estates/house2_1747146245212.png",
                "/data/estates/house15_1747146326683.png",
                "/data/estates/house14_1747146326667.png"
            ],
            deposit: 11507,
            monthlyRent: 4550,
            builtYear: "2012-08-07",
            area: 32.1,
            floors: 3,
            geolocation: Geolocation(lon: 127.037267, lat: 37.685533),
            distance: nil,
            likeCount: 0,
            isSafeEstate: false,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604755.336),
            updatedAt: Date(timeIntervalSince1970: 1715604755.336)
        ),
        Estate(
            id: "68235d141a1032c4e2d9c10c",
            category: "빌라",
            title: "햇살 가득 채광 좋은 집",
            introduction: "주차 2대 무료 제공!",
            thumbnails: [
                "/data/estates/house7_1747146288375.png",
                "/data/estates/house8_1747146288397.png",
                "/data/estates/house12_1747146326628.png"
            ],
            deposit: 25498,
            monthlyRent: 416,
            builtYear: "2016-08-30",
            area: 30.7,
            floors: 20,
            geolocation: Geolocation(lon: 127.026199, lat: 37.676688),
            distance: nil,
            likeCount: 0,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(timeIntervalSince1970: 1715604852.860),
            updatedAt: Date(timeIntervalSince1970: 1715604852.860)
        ),
        Estate(
            id: "68235be51a1032c4e2d9bb76",
            category: "원룸",
            title: "교통의 요지, 편리한 생활",
            introduction: "주변 학교 도보 10분 이내!",
            thumbnails: [
                "/data/estates/house10_1747146288434.png",
                "/data/estates/house6_1747146288315.png",
                "/data/estates/house7_1747146288375.png"
            ],
            deposit: 5000,
            monthlyRent: 6401,
            builtYear: "2012-05-01",
            area: 27.7,
            floors: 24,
            geolocation: Geolocation(lon: 127.021915, lat: 37.673265),
            distance: nil,
            likeCount: 0,
            isSafeEstate: false,
            isRecommended: false,
            createdAt: Date(timeIntervalSince1970: 1715604549.963),
            updatedAt: Date(timeIntervalSince1970: 1715604549.963)
        )
    ]
}


public struct Geolocation: Hashable {
    let lon: Double
    let lat: Double
}

/*
// - top banner Mock
 📥 Response Data: {"data":[{"estate_id":"6822b4cd3013b77fe7469e1f","category":"아파트","title":"새싹 파노라마 뷰\n역세권 아파트","introduction":"한강과 북한산 조망이 가능한 프리미엄 아파트","thumbnails":["/data/estates/example_1_1747104960999.jpg","/data/estates/example_2_1747104961017.jpg","/data/estates/example_3_1747104961024.jpg"],"deposit":8500000000,"monthly_rent":4500000,"built_year":"2022-05-15","area":84.5,"floors":25,"geolocation":{"longitude":127.043553,"latitude":37.650158},"like_count":1,"is_safe_estate":true,"is_recommended":true,"created_at":"2025-05-13T02:56:13.816Z","updated_at":"2025-08-09T12:25:12.503Z"},{"estate_id":"6822b5fd3013b77fe7469e2c","category":"오피스텔","title":"펜트하우스 오피스텔","introduction":"최고층 프라이빗 테라스 포함","thumbnails":["/data/estates/francesca-tosolini-w1RE0lBbREo-unsplash_1747105244716.jpg","/data/estates/michael-oxendine-GHCVUtBECuY-unsplash_1747105244880.jpg","/data/estates/spacejoy-umAXneH4GhA-unsplash_1747105245035.jpg"],"deposit":7200000000,"monthly_rent":3800000,"built_year":"2021-11-20","area":76.2,"floors":32,"geolocation":{"longitude":127.043553,"latitude":37.650158},"like_count":1,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T03:01:17.826Z","updated_at":"2025-09-12T12:58:01.698Z"},{"estate_id":"6822b6963013b77fe7469e39","category":"빌라","title":"창동 프리미엄 타운하우스","introduction":"정원과 테라스를 갖춘 고급 주택","thumbnails":["/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg","/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],"deposit":6500000000,"monthly_rent":3200000,"built_year":"2023-02-10","area":92.4,"floors":4,"geolocation":{"longitude":127.048421,"latitude":37.657372},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T03:03:50.844Z","updated_at":"2025-07-31T08:25:22.782Z"}]}
 // - hot estate mock
 📥 Response Data: {"data":[{"estate_id":"68235da61a1032c4e2d9c3be","category":"빌라","title":"공원 근처 쾌적한 환경","introduction":"24시간 보안 시스템!","thumbnails":["/data/estates/house9_1747146288414.png","/data/estates/house8_1747146288397.png","/data/estates/house11_1747146326584.png"],"deposit":2831,"monthly_rent":12907,"built_year":"2011-05-22","area":21.3,"floors":12,"geolocation":{"longitude":127.063002,"latitude":37.616007},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T14:56:38.696Z","updated_at":"2025-05-13T14:56:38.696Z"},{"estate_id":"6822fefc1a1032c4e2d9b414","category":"아파트","title":"푸르지오 아파트","introduction":"짐만 오면 OK! 풀옵션 + 채광 좋은 신축 남향","thumbnails":["/data/estates/roberto-nickson-rEJxpBskj3Q-unsplash_1747107238994.jpg","/data/estates/michael-oxendine-BfkTFeysp34-unsplash_1747107239103.jpg","/data/estates/spacejoy-nEtpvJjnPVo-unsplash_1747107239209.jpg"],"deposit":150000000,"monthly_rent":3000000,"built_year":"2022-05-15","area":84,"floors":9,"geolocation":{"longitude":127.05191994611108,"latitude":37.653585669845036},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T08:12:44.741Z","updated_at":"2025-05-13T08:12:44.741Z"},{"estate_id":"68235cb31a1032c4e2d9bf40","category":"아파트","title":"헬스장과 수영장이 있는 고급 주택","introduction":"전기차 충전소 설치!","thumbnails":["/data/estates/house2_1747146245212.png","/data/estates/house15_1747146326683.png","/data/estates/house14_1747146326667.png"],"deposit":11507,"monthly_rent":4550,"built_year":"2012-08-07","area":32.1,"floors":3,"geolocation":{"longitude":127.037267,"latitude":37.685533},"like_count":0,"is_safe_estate":false,"is_recommended":false,"created_at":"2025-05-13T14:52:35.336Z","updated_at":"2025-05-13T14:52:35.336Z"},{"estate_id":"68235d141a1032c4e2d9c10c","category":"빌라","title":"햇살 가득 채광 좋은 집","introduction":"주차 2대 무료 제공!","thumbnails":["/data/estates/house7_1747146288375.png","/data/estates/house8_1747146288397.png","/data/estates/house12_1747146326628.png"],"deposit":25498,"monthly_rent":416,"built_year":"2016-08-30","area":30.7,"floors":20,"geolocation":{"longitude":127.026199,"latitude":37.676688},"like_count":0,"is_safe_estate":true,"is_recommended":true,"created_at":"2025-05-13T14:54:12.860Z","updated_at":"2025-05-13T14:54:12.860Z"},{"estate_id":"68235be51a1032c4e2d9bb76","category":"원룸","title":"교통의 요지, 편리한 생활","introduction":"주변 학교 도보 10분 이내!","thumbnails":["/data/estates/house10_1747146288434.png","/data/estates/house6_1747146288315.png","/data/estates/house7_1747146288375.png"],"deposit":5000,"monthly_rent":6401,"built_year":"2012-05-01","area":27.7,"floors":24,"geolocation":{"longitude":127.021915,"latitude":37.673265},"like_count":0,"is_safe_estate":false,"is_recommended":false,"created_at":"2025-05-13T14:49:09.963Z","updated_at":"2025-05-13T14:49:09.963Z"},{"estate_id":"68235bd31a1032c4e2d9bb1c","category":"오피스텔","title":"편의시설 완비 스마트홈","introduction":"열효율 최고 난방비 절약!","thumbnails":["/data/estates/house14_1747146326667.png","/data/estates/house15_1747146326683.png","/data/estates/house4_1747146245264.png"],"deposit":21392,"monthly_rent":19158,"built_year":"2017-09-14","area":32,"floors":6,"geolocation":{"longitude":127.03084,"latitude":37.680397},"like_count":0,"is_safe_estate":false,"is_recommended":true,"created_at":"2025-05-13T14:48:51.096Z","updated_at":"2025-05-13T14:48:51.096Z"},{"estate_id":"689c81586d6f93081d7b01ae","category":"아파트","title":"정아니의 해피하우스 25","introduction":"사랑을 느낄 수 있는 안락한 집 25","thumbnails":["/data/estates/house4_1747146245264.png"],"deposit":19435483,"monthly_rent":4873168,"built_year":"2024-07-13","area":64.4,"floors":10,"geolocation":{"longitude":126.931603,"latitude":37.461726},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-08-13T12:13:12.454Z","updated_at":"2025-08-13T12:13:12.454Z"},{"estate_id":"68235d911a1032c4e2d9c35a","category":"상가","title":"역세권 프리미엄 매물","introduction":"반려동물 friendly!","thumbnails":["/data/estates/house11_1747146326584.png","/data/estates/house17_1747146355023.png","/data/estates/house15_1747146326683.png"],"deposit":32178,"monthly_rent":12380,"built_year":"2013-03-19","area":30.1,"floors":22,"geolocation":{"longitude":127.055591,"latitude":37.610085},"like_count":0,"is_safe_estate":false,"is_recommended":true,"created_at":"2025-05-13T14:56:17.657Z","updated_at":"2025-05-13T14:56:17.657Z"},{"estate_id":"68235e091a1032c4e2d9c594","category":"빌라","title":"비즈니스 중심지 근처 효율적 주거","introduction":"단지내 상가 편리한 생활!","thumbnails":["/data/estates/house8_1747146288397.png","/data/estates/house16_1747146354975.png","/data/estates/house17_1747146355023.png"],"deposit":27517,"monthly_rent":17113,"built_year":"2017-12-22","area":27.4,"floors":3,"geolocation":{"longitude":127.087569,"latitude":37.635638},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T14:58:17.565Z","updated_at":"2025-05-13T14:58:17.565Z"},{"estate_id":"68235c7e1a1032c4e2d9be46","category":"상가","title":"투자가치 높은 프리미엄 물건","introduction":"단지내 상가 편리한 생활!","thumbnails":["/data/estates/house16_1747146354975.png","/data/estates/house13_1747146326641.png","/data/estates/house12_1747146326628.png"],"deposit":32265,"monthly_rent":3062,"built_year":"2001-06-22","area":28.7,"floors":23,"geolocation":{"longitude":127.034167,"latitude":37.683056},"like_count":0,"is_safe_estate":true,"is_recommended":false,"created_at":"2025-05-13T14:51:42.424Z","updated_at":"2025-05-13T14:51:42.424Z"}]}
 */
