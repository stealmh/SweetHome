//
//  BannerEstateType.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation

enum BannerEstateType: String, CaseIterable {
    case oneRoom = "원룸"
    case officetel = "오피스텔"
    case apartment = "아파트"
    case villa = "빌라"
    case commercial = "상가"
    
    var imageName: String {
        switch self {
        case .oneRoom:
            return "one_room"
        case .officetel:
            return "officetel"
        case .apartment:
            return "apartment"
        case .villa:
            return "villa"
        case .commercial:
            return "storefront"
        }
    }
    
    var title: String {
        self.rawValue
    }
}
