//
//  DetailEstate.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import Foundation

// MARK: - Detailed Estate Domain Models
struct DetailEstate: Hashable {
    let id: String
    let category: String
    let title: String
    let introduction: String
    let reservationPrice: Int
    let thumbnails: [String]
    let description: String
    let deposit: Int
    let monthlyRent: Int
    let builtYear: String
    let maintenanceFee: Int
    let area: Float
    let parkingCount: Int
    let floors: Int
    let options: EstateOptions
    let geolocation: Geolocation
    let creator: Creator
    let isLiked: Bool
    let isReserved: Bool
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let comments: [Comment]
    let createdAt: Date
    let updatedAt: Date
}

struct EstateOptions: Hashable {
    let refrigerator: Bool
    let washer: Bool
    let airConditioner: Bool
    let closet: Bool
    let shoeRack: Bool
    let microwave: Bool
    let sink: Bool
    let tv: Bool
}

struct Creator: Hashable {
    let userId: String
    let nick: String
    let introduction: String
    let profileImage: String
}

struct Comment: Hashable {
    let commentId: String
    let content: String
    let createdAt: Date
    let creator: Creator
    let replies: [Comment]
}

// MARK: - Convenience Extensions
extension DetailEstate {
    /// 기본 Estate로 변환 (리스트에서 사용)
    var toBaseEstate: Estate {
        return Estate(
            id: self.id,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            thumbnails: self.thumbnails,
            deposit: self.deposit,
            monthlyRent: self.monthlyRent,
            builtYear: self.builtYear,
            area: self.area,
            floors: self.floors,
            geolocation: self.geolocation,
            distance: nil, // 상세에서는 거리 정보 없음
            likeCount: self.likeCount,
            isSafeEstate: self.isSafeEstate,
            isRecommended: self.isRecommended,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
    
    /// 월세 표시용 문자열
    var rentDisplayText: String {
        if monthlyRent == 0 {
            return "전세 \(deposit.formattedPrice)"
        } else {
            return "월세 \(deposit.formattedPrice)/\(monthlyRent.formattedPrice)"
        }
    }
    
    /// 위치와 면적 표시용 문자열
    var locationAndAreaText: String {
        return "\(area)m²" // TODO: 위치 정보 추가 시 "문래동 \(area)m²"
    }
}

extension Int {
    /// 가격을 만원 단위로 포맷팅
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        
        if self >= 10000 {
            let billionPart = self / 10000
            let remainingPart = self % 10000
            if remainingPart == 0 {
                return "\(formatter.string(from: NSNumber(value: billionPart)) ?? "\(billionPart)")억"
            } else {
                return "\(formatter.string(from: NSNumber(value: billionPart)) ?? "\(billionPart)")억 \(formatter.string(from: NSNumber(value: remainingPart)) ?? "\(remainingPart)")"
            }
        } else {
            return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        }
    }
}