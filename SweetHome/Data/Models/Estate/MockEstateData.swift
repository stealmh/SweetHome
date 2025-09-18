//
//  MockEstateData.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import Foundation

// MARK: - Mock Data for Testing
extension DetailEstate {
    static let mockData: [DetailEstate] = [
        DetailEstate(
            id: "670bcd66539a670e42b2a3d8",
            category: "오피스텔",
            title: "고즈넉 매물, 여기가 진국",
            introduction: "풀옵션, 즉시 입주 가능!",
            reservationPrice: 100,
            thumbnails: ["/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg"],
            description: "서울 문래동에 위치한 문래동 롯데캐슬은 뛰어난 교통 접근성과 쾌적한 주거 환경을 갖춘 프리미엄 아파트입니다.",
            deposit: 1000000,
            monthlyRent: 5000000,
            builtYear: "2020-01-04",
            maintenanceFee: 5,
            area: 25.5,
            parkingCount: 1,
            floors: 1,
            options: EstateOptions(
                refrigerator: true,
                washer: true,
                airConditioner: true,
                closet: true,
                shoeRack: true,
                microwave: true,
                sink: true,
                tv: true
            ),
            geolocation: Geolocation(lon: 126.886557, lat: 37.51775),
            creator: Creator(
                userId: "65c9aa6932b0964405117d97",
                nick: "새싹중개인",
                introduction: "언제나 친절한 상담을 제공합니다.",
                profileImage: "/data/profiles/1707716853682.png"
            ),
            isLiked: true,
            isReserved: true,
            likeCount: 5,
            isSafeEstate: true,
            isRecommended: true,
            comments: [
                Comment(
                    commentId: "65c9bc50a76c82debcf0e3e3",
                    content: "안녕하세요 ~ 반갑습니다.",
                    createdAt: Date(),
                    creator: Creator(
                        userId: "65c9aa6932b0964405117d97",
                        nick: "새싹중개인",
                        introduction: "언제나 친절한 상담을 제공합니다.",
                        profileImage: "/data/profiles/1707716853682.png"
                    ),
                    replies: [
                        Comment(
                            commentId: "65c9bc50a76c82debcf0e3e4",
                            content: "문의사항 있습니다.",
                            createdAt: Date(),
                            creator: Creator(
                                userId: "65c9aa6932b0964405117d98",
                                nick: "구매희망자",
                                introduction: "",
                                profileImage: "/data/profiles/default.png"
                            ),
                            replies: []
                        )
                    ]
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        DetailEstate(
            id: "670bcd66539a670e42b2a3d9",
            category: "원룸",
            title: "신축 원룸, 깔끔한 인테리어",
            introduction: "역세권 신축 원룸",
            reservationPrice: 50,
            thumbnails: ["/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],
            description: "지하철 2호선 문래역 도보 5분 거리의 신축 원룸입니다.",
            deposit: 500000000,
            monthlyRent: 450000,
            builtYear: "2023-03-15",
            maintenanceFee: 8,
            area: 18.2,
            parkingCount: 0,
            floors: 1,
            options: EstateOptions(
                refrigerator: true,
                washer: false,
                airConditioner: true,
                closet: true,
                shoeRack: true,
                microwave: true,
                sink: true,
                tv: false
            ),
            geolocation: Geolocation(lon: 126.888557, lat: 37.51875),
            creator: Creator(
                userId: "65c9aa6932b0964405117d98",
                nick: "믿음부동산",
                introduction: "20년 경력의 전문 공인중개사입니다.",
                profileImage: "/data/profiles/1707716853683.png"
            ),
            isLiked: false,
            isReserved: false,
            likeCount: 12,
            isSafeEstate: true,
            isRecommended: false,
            comments: [],
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        DetailEstate(
            id: "670bcd66539a670e42b2a3da",
            category: "아파트",
            title: "한강뷰 아파트, 최고의 조망",
            introduction: "한강이 한눈에! 프리미엄 아파트",
            reservationPrice: 200,
            thumbnails: ["/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],
            description: "한강공원과 인접한 최고층 아파트로 탁 트인 한강뷰를 자랑합니다.",
            deposit: 50000,
            monthlyRent: 0, // 전세
            builtYear: "2018-11-20",
            maintenanceFee: 15,
            area: 84.3,
            parkingCount: 2,
            floors: 25,
            options: EstateOptions(
                refrigerator: true,
                washer: true,
                airConditioner: true,
                closet: true,
                shoeRack: true,
                microwave: true,
                sink: true,
                tv: true
            ),
            geolocation: Geolocation(lon: 126.890557, lat: 37.52075),
            creator: Creator(
                userId: "65c9aa6932b0964405117d99",
                nick: "한강부동산",
                introduction: "한강뷰 전문 매물을 취급합니다.",
                profileImage: "/data/profiles/1707716853684.png"
            ),
            isLiked: true,
            isReserved: false,
            likeCount: 28,
            isSafeEstate: true,
            isRecommended: true,
            comments: [
                Comment(
                    commentId: "65c9bc50a76c82debcf0e3e5",
                    content: "한강뷰가 정말 멋지네요!",
                    createdAt: Date(),
                    creator: Creator(
                        userId: "65c9aa6932b0964405117d9a",
                        nick: "아파트매니아",
                        introduction: "",
                        profileImage: "/data/profiles/default.png"
                    ),
                    replies: []
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

// MARK: - Estate Mock Data
struct MockEstateData {
    static let hotEstates: [Estate] = [
        Estate(
            id: "hot1",
            category: "오피스텔",
            title: "🔥역세권 신축 오피스텔",
            introduction: "지하철 2분거리 초역세권",
            thumbnails: ["/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg"],
            deposit: 10000000,
            monthlyRent: 800000,
            builtYear: "2024-01-01",
            area: 30.5,
            floors: 12,
            geolocation: Geolocation(lon: 126.886557, lat: 37.51775),
            distance: nil,
            likeCount: 45,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Estate(
            id: "hot2",
            category: "원룸",
            title: "🔥신설동 신축 원룸",
            introduction: "풀옵션 즉시입주 가능",
            thumbnails: ["/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],
            deposit: 6500000,
            monthlyRent: 450000,
            builtYear: "2023-12-15",
            area: 22.3,
            floors: 8,
            geolocation: Geolocation(lon: 126.888557, lat: 37.51875),
            distance: nil,
            likeCount: 32,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Estate(
            id: "hot3",
            category: "아파트",
            title: "🔥한강뷰 프리미엄 아파트",
            introduction: "한강이 한눈에 들어오는 최고층",
            thumbnails: ["/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg"],
            deposit: 80000,
            monthlyRent: 0, // 전세
            builtYear: "2019-05-20",
            area: 84.5,
            floors: 25,
            geolocation: Geolocation(lon: 126.890557, lat: 37.52075),
            distance: nil,
            likeCount: 67,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Estate(
            id: "hot4",
            category: "투룸",
            title: "🔥넓은 투룸 베란다 있음",
            introduction: "신혼부부 추천 매물",
            thumbnails: ["/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"],
            deposit: 3000,
            monthlyRent: 120,
            builtYear: "2021-08-10",
            area: 45.2,
            floors: 5,
            geolocation: Geolocation(lon: 126.892557, lat: 37.51975),
            distance: nil,
            likeCount: 23,
            isSafeEstate: true,
            isRecommended: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

// MARK: - BaseEstateDataResponse Mock Data
extension BaseEstateDataResponse {
    static let mockTodayEstates: [BaseEstateDataResponse] = [
        BaseEstateDataResponse(
            estate_id: "6822b4cd3013b77fe7469e1f",
            category: "아파트",
            title: "신반포역 도보3분\n역세권 아파트",
            introduction: "반포한강공원, 종합운동장이 위치해 산책하기 좋은 곳",
            thumbnails: [
                "/data/estates/example_1_1747104960999.jpg",
                "/data/estates/example_2_1747104961017.jpg",
                "/data/estates/example_3_1747104961024.jpg"
            ],
            deposit: 8500000000,
            monthly_rent: 4500000,
            built_year: "2022-05-15",
            area: 84.5,
            floors: 25,
            geolocation: BaseGeolocationResponse(longitude: 127.043553, latitude: 37.650158),
            distance: nil,
            like_count: 1,
            is_safe_estate: true,
            is_recommended: true,
            created_at: "2025-05-13T02:56:13.816Z",
            updated_at: "2025-08-09T12:25:12.503Z"
        ),
        BaseEstateDataResponse(
            estate_id: "6822b5fd3013b77fe7469e2c",
            category: "오피스텔",
            title: "펜트하우스 오피스텔",
            introduction: "최고층 프라이빗 테라스 포함",
            thumbnails: [
                "/data/estates/francesca-tosolini-w1RE0lBbREo-unsplash_1747105244716.jpg",
                "/data/estates/michael-oxendine-GHCVUtBECuY-unsplash_1747105244880.jpg",
                "/data/estates/spacejoy-umAXneH4GhA-unsplash_1747105245035.jpg"
            ],
            deposit: 7200000000,
            monthly_rent: 3800000,
            built_year: "2021-11-20",
            area: 76.2,
            floors: 32,
            geolocation: BaseGeolocationResponse(longitude: 127.043553, latitude: 37.650158),
            distance: nil,
            like_count: 1,
            is_safe_estate: true,
            is_recommended: false,
            created_at: "2025-05-13T03:01:17.826Z",
            updated_at: "2025-09-12T12:58:01.698Z"
        ),
        BaseEstateDataResponse(
            estate_id: "6822b6963013b77fe7469e39",
            category: "빌라",
            title: "창동 프리미엄 타운하우스",
            introduction: "정원과 테라스를 갖춘 고급 주택",
            thumbnails: [
                "/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg",
                "/data/estates/collov-home-design-4_jQL4JCS98-unsplash_1747105359959.jpg"
            ],
            deposit: 6500000000,
            monthly_rent: 3200000,
            built_year: "2023-02-10",
            area: 92.4,
            floors: 4,
            geolocation: BaseGeolocationResponse(longitude: 127.048421, latitude: 37.657372),
            distance: nil,
            like_count: 0,
            is_safe_estate: true,
            is_recommended: false,
            created_at: "2025-05-13T03:03:50.844Z",
            updated_at: "2025-07-31T08:25:22.782Z"
        )
    ]

    static let mockHotEstates: [BaseEstateDataResponse] = [
        BaseEstateDataResponse(
            estate_id: "68235da61a1032c4e2d9c3be",
            category: "빌라",
            title: "공원 근처 쾌적한 환경",
            introduction: "24시간 보안 시스템!",
            thumbnails: [
                "/data/estates/house9_1747146288414.png",
                "/data/estates/house8_1747146288397.png",
                "/data/estates/house11_1747146326584.png"
            ],
            deposit: 200000000,
            monthly_rent: 600000,
            built_year: "2011-05-22",
            area: 21.3,
            floors: 12,
            geolocation: BaseGeolocationResponse(longitude: 127.063002, latitude: 37.616007),
            distance: nil,
            like_count: 0,
            is_safe_estate: true,
            is_recommended: false,
            created_at: "2025-05-13T14:56:38.696Z",
            updated_at: "2025-05-13T14:56:38.696Z"
        ),
        BaseEstateDataResponse(
            estate_id: "6822fefc1a1032c4e2d9b414",
            category: "아파트",
            title: "푸르지오 아파트",
            introduction: "짐만 오면 OK! 풀옵션 + 채광 좋은 신축 남향",
            thumbnails: [
                "/data/estates/roberto-nickson-rEJxpBskj3Q-unsplash_1747107238994.jpg",
                "/data/estates/michael-oxendine-BfkTFeysp34-unsplash_1747107239103.jpg",
                "/data/estates/spacejoy-nEtpvJjnPVo-unsplash_1747107239209.jpg"
            ],
            deposit: 150000000,
            monthly_rent: 3000000,
            built_year: "2022-05-15",
            area: 84,
            floors: 9,
            geolocation: BaseGeolocationResponse(longitude: 127.05191994611108, latitude: 37.653585669845036),
            distance: nil,
            like_count: 0,
            is_safe_estate: true,
            is_recommended: false,
            created_at: "2025-05-13T08:12:44.741Z",
            updated_at: "2025-05-13T08:12:44.741Z"
        )
    ]
}

// MARK: - Mock Response Data
extension DetailEstateResponse {
    static let mockResponseData: [DetailEstateResponse] = [
        DetailEstateResponse(
            estate_id: "670bcd66539a670e42b2a3d8",
            category: "오피스텔",
            title: "고즈넉 매물, 여기가 진국",
            introduction: "풀옵션, 즉시 입주 가능!",
            reservation_price: 100,
            thumbnails: ["/data/estates/example_2_1747104961017.jpg"],
            description: "서울 문래동에 위치한 문래동 롯데캐슬은 뛰어난 교통 접근성과 쾌적한 주거 환경을 갖춘 프리미엄 아파트입니다.",
            deposit: 10000000,
            monthly_rent: 500000,
            built_year: "2020-01-04",
            maintenance_fee: 50000,
            area: 25.5,
            parking_count: 1,
            floors: 1,
            options: EstateOptionsResponse(
                refrigerator: true,
                washer: true,
                air_conditioner: true,
                closet: true,
                shoe_rack: true,
                microwave: true,
                sink: true,
                tv: true
            ),
            geolocation: BaseGeolocationResponse(longitude: 126.886557, latitude: 37.51775),
            creator: CreatorResponse(
                user_id: "65c9aa6932b0964405117d97",
                nick: "새싹중개인",
                introduction: "언제나 친절한 상담을 제공합니다.",
                profileImage: "/data/profiles/1707716853682.png"
            ),
            is_liked: true,
            is_reserved: true,
            like_count: 5,
            is_safe_estate: true,
            is_recommended: true,
            comments: [
                CommentResponse(
                    comment_id: "65c9bc50a76c82debcf0e3e3",
                    content: "안녕하세요 ~ 반갑습니다.",
                    createdAt: "9999-02-12T06:36:00.073Z",
                    creator: CreatorResponse(
                        user_id: "65c9aa6932b0964405117d97",
                        nick: "새싹중개인",
                        introduction: "언제나 친절한 상담을 제공합니다.",
                        profileImage: "/data/profiles/1707716853682.png"
                    ),
                    replies: [
                        CommentResponse(
                            comment_id: "65c9bc50a76c82debcf0e3e3",
                            content: "문의사항 있습니다.",
                            createdAt: "9999-02-12T06:36:00.073Z",
                            creator: CreatorResponse(
                                user_id: "65c9aa6932b0964405117d97",
                                nick: "새싹중개인",
                                introduction: "언제나 친절한 상담을 제공합니다.",
                                profileImage: "/data/profiles/1707716853682.png"
                            ),
                            replies: nil
                        )
                    ]
                )
            ],
            created_at: "9999-10-19T03:05:03.422Z",
            updated_at: "9999-10-20T04:10:10.123Z"
        )
    ]
}
