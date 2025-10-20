//
//  BaseGeolocationResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//


struct BaseGeolocationResponse: Hashable, Decodable {
    let longitude: Double
    let latitude: Double
}
