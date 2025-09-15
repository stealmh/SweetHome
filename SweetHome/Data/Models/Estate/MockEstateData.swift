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
