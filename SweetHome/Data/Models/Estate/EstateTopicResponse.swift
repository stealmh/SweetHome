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
