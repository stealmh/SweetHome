//
//  EstateGeoLocationRequest.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import Foundation

struct EstateGeoLocationRequest: Encodable {
    let category: String
    let longitude: String
    let latitude: String
    let maxDistance: Int
}
