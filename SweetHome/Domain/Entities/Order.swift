//
//  Order.swift
//  SweetHome
//
//  Created by 김민호 on 10/16/25.
//

import Foundation

// MARK: - Order Domain Models

/// - 주문 정보
public struct Order {
    public let orderId: String
    public let orderCode: String
    public let totalPrice: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        orderId: String,
        orderCode: String,
        totalPrice: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.orderId = orderId
        self.orderCode = orderCode
        self.totalPrice = totalPrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// - 결제 검증 결과
public struct PaymentValidation {
    public let paymentId: String
    public let orderItem: OrderItem
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        paymentId: String,
        orderItem: OrderItem,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.paymentId = paymentId
        self.orderItem = orderItem
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// - 주문 항목
public struct OrderItem {
    public let orderId: String
    public let orderCode: String
    public let estate: OrderEstate
    public let paidAt: Date
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        orderId: String,
        orderCode: String,
        estate: OrderEstate,
        paidAt: Date,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.orderId = orderId
        self.orderCode = orderCode
        self.estate = estate
        self.paidAt = paidAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// - 결제 결과 (아임포트)
public struct PaymentResult {
    public let success: Bool
    public let impUid: String?
    public let merchantUid: String?
    public let errorMessage: String?
    public let errorCode: String?

    public init(
        success: Bool,
        impUid: String?,
        merchantUid: String?,
        errorMessage: String?,
        errorCode: String?
    ) {
        self.success = success
        self.impUid = impUid
        self.merchantUid = merchantUid
        self.errorMessage = errorMessage
        self.errorCode = errorCode
    }
}

/// - 주문 내 매물 정보 (간소화된 버전)
public struct OrderEstate {
    public let id: String
    public let category: String
    public let title: String
    public let introduction: String
    public let thumbnails: [String]
    public let deposit: Int
    public let monthlyRent: Int
    public let builtYear: String
    public let area: Float
    public let floors: Int
    public let geolocation: Geolocation
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        category: String,
        title: String,
        introduction: String,
        thumbnails: [String],
        deposit: Int,
        monthlyRent: Int,
        builtYear: String,
        area: Float,
        floors: Int,
        geolocation: Geolocation,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.introduction = introduction
        self.thumbnails = thumbnails
        self.deposit = deposit
        self.monthlyRent = monthlyRent
        self.builtYear = builtYear
        self.area = area
        self.floors = floors
        self.geolocation = geolocation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
