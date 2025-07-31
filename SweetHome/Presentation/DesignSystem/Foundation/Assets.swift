//
//  Assets.swift
//  SweetHome
//
//  Created by 김민호 on 7/28/25.
//

import UIKit

enum SHAsset {
    enum Category {
        static let apartment = UIImage(named: "apartment")
        static let officetel = UIImage(named: "officetel")
        static let oneRoom = UIImage(named: "one_room")
        static let storefront = UIImage(named: "storefront")
        static let villa = UIImage(named: "villa")
    }
    
    enum Icon {
        static let chevron = UIImage(named: "chevron")
        static let fire = UIImage(named: "fire")
        static let focus = UIImage(named: "focus")
        static let frame = UIImage(named: "frame")
        static let likeEmpty = UIImage(named: "like_empty")
        static let likeFill = UIImage(named: "like_fill")
        static let list = UIImage(named: "list")
        static let location = UIImage(named: "location")
        static let map = UIImage(named: "map")
        static let phone = UIImage(named: "phone")
        static let safety = UIImage(named: "safty")
        static let search = UIImage(named: "search")
        static let sort = UIImage(named: "sort")
    }
    
    enum Option {
        static let airConditioner = UIImage(named: "airconditioner")
        static let closet = UIImage(named: "closet")
        static let microwave = UIImage(named: "microwave")
        static let parking = UIImage(named: "parking")
        static let refrigerator = UIImage(named: "refrigerator")
        static let shoeCabinet = UIImage(named: "shoecabinet")
        static let sink = UIImage(named: "sink")
        static let television = UIImage(named: "television")
        static let washingMachine = UIImage(named: "washingmachine")
    }
    
    enum TabBar {
        static let homeEmpty = UIImage(named: "home_empty")
        static let homeFill = UIImage(named: "home_fill")
        static let interestEmpty = UIImage(named: "interest_empty")
        static let interestFill = UIImage(named: "interest_fill")
        static let settingEmpty = UIImage(named: "setting_empty")
        static let settingFill = UIImage(named: "setting_fill")
    }
    
    enum LoginIcon {
        static let apple = UIImage(named: "appleid_button")
        static let kakao = UIImage(named: "kakao")
    }
}
