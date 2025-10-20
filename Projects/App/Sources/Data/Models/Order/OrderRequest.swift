//
//  OrderRequest.swift
//  SweetHome
//
//  Created by 김민호 on 8/27/25.
//

/// - 주문 생성 Body
struct OrderRequest: Encodable {
    let estate_id: String
    let total_price: Int
}

