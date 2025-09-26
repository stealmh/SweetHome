//
//  Int+.swift
//  SweetHome
//
//  Created by 김민호 on 8/13/25.
//

import Foundation

extension Int {
    
    /// 천 단위 콤마 포맷팅 (예: 3000 → "3,000")
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// 가격을 만원/억 단위로 포맷팅 (숫자만 or 억 단위)
    /// - 1억 미만: 숫자만 표시 (예: 30000000 → "300")
    /// - 1억 이상: 억 단위 표시 (예: 110000000 → "1.1억")
    var formattedPrice: String {
        if self >= 100_000_000 {
            // 1억 이상: 억 단위 표시
            let eokUnit = Double(self) / 100_000_000.0

            /// - 소수점 첫째자리에서 반올림
            let rounded = round(eokUnit * 10) / 10

            /// - 반올림된 값이 정수인지 확인
            if rounded == floor(rounded) {
                return "\(Int(rounded))억"
            } else {
                return String(format: "%.1f억", rounded)
            }
        } else {
            // 1억 미만: 만원 단위 숫자만
            return "\(self / 10_000)"
        }
    }
    
    
    /// 가격을 전체 단위로 포맷팅 (만원/억 표시 포함)
    /// - 만원 단위: "53만" 형태로 표시
    /// - 억 단위: "1.3억" 형태로 표시
    var formattedPriceWithUnit: String {
        let manWonUnit = self / 10000  // 만원 단위로 변환
        
        if manWonUnit >= 10000 {
            // 억 단위
            let eokUnit = Double(manWonUnit) / 10000.0
            if eokUnit == floor(eokUnit) {
                // 소수점이 없는 경우
                return "\(Int(eokUnit))억"
            } else {
                // 소수점 첫째자리까지 표시
                return String(format: "%.1f억", eokUnit)
            }
        } else {
            // 만원 단위
            if manWonUnit == 0 {
                return "0"
            } else {
                return "\(manWonUnit)만"
            }
        }
    }
}
