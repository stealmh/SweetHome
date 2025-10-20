//
//  OrderResponse.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

struct OrderResponse: Decodable {
    let order_id: String
    /// - 아임포트에 결제 요청시 결제 데이터의 merchant_uid
    let order_code: String
    let total_price: Int
    let createdAt: String
    let updatedAt: String
}
