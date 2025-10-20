//
//  DetailEstate.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

import Foundation

// MARK: - Detailed Estate Domain Models
public struct DetailEstate: Hashable {
    public let id: String
    public let category: String
    public let title: String
    public let introduction: String
    public let reservationPrice: Int
    public let thumbnails: [String]
    public let description: String
    public let deposit: Int
    public let monthlyRent: Int
    public let builtYear: String
    public let maintenanceFee: Int
    public let area: Float
    public let parkingCount: Int
    public let floors: Int
    public let options: EstateOptions
    public let geolocation: Geolocation
    public let creator: Creator
    public let isLiked: Bool
    public let isReserved: Bool
    public let likeCount: Int
    public let isSafeEstate: Bool
    public let isRecommended: Bool
    public let comments: [Comment]
    public let createdAt: Date
    public let updatedAt: Date
}

public struct EstateOptions: Hashable {
    public let refrigerator: Bool
    public let washer: Bool
    public let airConditioner: Bool
    public let closet: Bool
    public let shoeRack: Bool
    public let microwave: Bool
    public let sink: Bool
    public let tv: Bool
}

public struct Creator: Hashable {
    public let userId: String
    public let nick: String
    public let introduction: String?
    public let profileImage: String?
}

public struct Comment: Hashable {
    public let commentId: String
    public let content: String
    public let createdAt: Date
    public let creator: Creator
    public let replies: [Comment]
}

// MARK: - Convenience Extensions
public extension DetailEstate {
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
    
    /// 전세,월세 구분
    var rentTypeText: String {
        return monthlyRent == 0 ? "전세" : "월세"
    }
    
    /// 월세 표시용 문자열
    var rentDisplayText: String {
        if monthlyRent == 0 {
            return "\(deposit.formattedPrice)"
        } else {
            return "\(deposit.formattedPrice)/\(monthlyRent.formattedPrice)"
        }
    }
    
    /// 위치와 면적 표시용 문자열
    var locationAndAreaText: String {
        return "\(area)m²" // TODO: 위치 정보 추가 시 "문래동 \(area)m²"
    }
    
    /// updatedAt 기준으로 며칠 전인지 반환
    var daysAgoText: String {
        let now = Date()
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: updatedAt, to: now).day ?? 0
        
        if daysDifference == 0 {
            return "오늘"
        } else if daysDifference == 1 {
            return "1일 전"
        } else {
            return "\(daysDifference)일 전"
        }
    }
    
    /// 관리비 포맷팅
    var formattedMaintenanceFee: String {
        if maintenanceFee == 0 { return "없음" }
        
        let manWon = Double(maintenanceFee) / 10000.0
        
        if manWon == floor(manWon) { return "\(Int(manWon))만원" }
        
        return String(format: "%.1f만원", manWon)
    }
}
