//
//  EstateTopic.swift
//  SweetHome
//
//  Created by 김민호 on 8/4/25.
//

public struct EstateTopic: Hashable {
    public let title: String
    public let content: String
    // format: "25.4.4"
    public let date: String
    public let link: String?
}

// MARK: - Mock Data
public extension EstateTopic {
    static let mockData: [EstateTopic] = [
        EstateTopic(
            title: "부동산 시장 동향",
            content: "최근 부동산 시장의 변화와 전망",
            date: "25.1.15",
            link: "https://example.com/news/1"
        ),
        EstateTopic(
            title: "주택 청약 가이드",
            content: "2025년 주택 청약 신청 방법",
            date: "25.1.10",
            link: "https://example.com/news/2"
        )
    ]
}
