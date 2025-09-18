//
//  EstateTopicResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

/// - 오늘의 부동산 Topic 조회
struct EstateTopicResponse: Decodable {
    let data: [EstateTopicDataResponse]
}

struct EstateTopicDataResponse: Decodable {
    let title: String
    let content: String
    // format: "25.4.4"
    let date: String
    let link: String?
}

// MARK: - Domain Mapping
extension EstateTopicDataResponse {
    var toDomain: EstateTopic {
        return EstateTopic(
            title: self.title,
            content: self.content,
            date: self.date,
            link: self.link
        )
    }
}

// MARK: - Mock Data
extension EstateTopicDataResponse {
    static let mockData: [EstateTopicDataResponse] = [
        EstateTopicDataResponse(
            title: "부동산 시장 동향",
            content: "최근 부동산 시장의 변화와 전망",
            date: "25.1.15",
            link: "https://example.com/news/1"
        ),
        EstateTopicDataResponse(
            title: "주택 청약 가이드",
            content: "2025년 주택 청약 신청 방법",
            date: "25.1.10",
            link: "https://example.com/news/2"
        )
    ]
}
