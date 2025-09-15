//
//  PaymentValidationResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

struct PaymentValidationResponse: Decodable {
    let payment_id: String
    let order_item: PaymentOrderItem
    let createdAt: String
    let updatedAt: String
}

struct PaymentOrderItem: Decodable {
    let order_id: String
    let order_code: String
    let estate: PaymentEstateInfo
    let paidAt: String
    let createdAt: String
    let updatedAt: String
}

struct PaymentEstateInfo: Decodable {
    let id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let area: Float
    let floors: Int
    let geolocation: BaseGeolocationResponse
    let createdAt: String
    let updatedAt: String
}
