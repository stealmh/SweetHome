//
//  DetailEstateResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import Foundation

// MARK: - Detail Estate Response Models
struct DetailEstateResponse: Decodable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let reservation_price: Int
    let thumbnails: [String]
    let description: String
    let deposit: Int
    let monthly_rent: Int
    let built_year: String // 2020-01-04
    let maintenance_fee: Int
    let area: Float
    let parking_count: Int
    let floors: Int
    let options: EstateOptionsResponse
    let geolocation: BaseGeolocationResponse
    let creator: CreatorResponse
    let is_liked: Bool
    let is_reserved: Bool
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let comments: [CommentResponse]
    let created_at: String
    let updated_at: String
}

struct EstateOptionsResponse: Decodable {
    let refrigerator: Bool?
    let washer: Bool?
    let air_conditioner: Bool?
    let closet: Bool?
    let shoe_rack: Bool?
    let microwave: Bool?
    let sink: Bool?
    let tv: Bool?
}

struct CreatorResponse: Decodable {
    let user_id: String
    let nick: String
    let introduction: String
    let profileImage: String?
}

struct CommentResponse: Decodable {
    let comment_id: String
    let content: String
    let createdAt: String
    let creator: CreatorResponse
    let replies: [CommentResponse]?
}

// MARK: - Domain Conversion
extension DetailEstateResponse {
    var toDomain: DetailEstate {
        return DetailEstate(
            id: self.estate_id,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            reservationPrice: self.reservation_price,
            thumbnails: self.thumbnails,
            description: self.description,
            deposit: self.deposit,
            monthlyRent: self.monthly_rent,
            builtYear: self.built_year,
            maintenanceFee: self.maintenance_fee,
            area: self.area,
            parkingCount: self.parking_count,
            floors: self.floors,
            options: self.options.toDomain,
            geolocation: Geolocation(
                lon: self.geolocation.longitude,
                lat: self.geolocation.latitude
            ),
            creator: self.creator.toDomain,
            isLiked: self.is_liked,
            isReserved: self.is_reserved,
            likeCount: self.like_count,
            isSafeEstate: self.is_safe_estate,
            isRecommended: self.is_recommended,
            comments: self.comments.map { $0.toDomain },
            createdAt: self.created_at.toISO8601Date() ?? Date(),
            updatedAt: self.updated_at.toISO8601Date() ?? Date()
        )
    }
}

extension EstateOptionsResponse {
    var toDomain: EstateOptions {
        return EstateOptions(
            refrigerator: self.refrigerator ?? false,
            washer: self.washer ?? false,
            airConditioner: self.air_conditioner ?? false,
            closet: self.closet ?? false,
            shoeRack: self.shoe_rack ?? false,
            microwave: self.microwave ?? false,
            sink: self.sink ?? false,
            tv: self.tv ?? false
        )
    }
}

extension CreatorResponse {
    var toDomain: Creator {
        return Creator(
            userId: self.user_id,
            nick: self.nick,
            introduction: self.introduction,
            profileImage: self.profileImage
        )
    }
}

extension CommentResponse {
    var toDomain: Comment {
        return Comment(
            commentId: self.comment_id,
            content: self.content,
            createdAt: Date(), // TODO: String을 Date로 파싱
            creator: self.creator.toDomain,
            replies: self.replies?.map { $0.toDomain } ?? []
        )
    }
}
