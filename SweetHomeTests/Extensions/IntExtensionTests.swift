/// - IntExtensionTests: Int Extension의 포맷팅 기능들을 테스트
/// - 천단위 콤마, 가격 포맷팅 (만원/억 단위) 테스트

import XCTest
@testable import SweetHome

final class IntExtensionTests: XCTestCase {

    // MARK: - Comma Formatting Tests

    func test_formattedWithComma_기본_케이스들() {
        let testCases: [(input: Int, expected: String)] = [
            (0, "0"),
            (100, "100"),
            (1000, "1,000"),
            (12345, "12,345"),
            (1000000, "1,000,000"),
            (123456789, "123,456,789")
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedWithComma, expected, "\(input)의 콤마 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    func test_formattedWithComma_음수() {
        let testCases: [(input: Int, expected: String)] = [
            (-1000, "-1,000"),
            (-12345, "-12,345"),
            (-1000000, "-1,000,000")
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedWithComma, expected, "\(input)의 콤마 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    // MARK: - Price Formatting Tests (formattedPrice)

    func test_formattedPrice_1억_미만() {
        let testCases: [(input: Int, expected: String)] = [
            (100_000, "10"),        // 10만원 = 10
            (5_000_000, "500"),     // 500만원 = 500
            (30_000_000, "3000"),   // 3000만원 = 3000
            (99_999_999, "9999")    // 약 1억 미만
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedPrice, expected, "\(input)의 가격 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    func test_formattedPrice_1억_이상() {
        let testCases: [(input: Int, expected: String)] = [
            (100_000_000, "1억"),      // 정확히 1억
            (150_000_000, "1.5억"),    // 1억 5천만
            (200_000_000, "2억"),      // 정확히 2억
            (230_000_000, "2.3억"),    // 2억 3천만
            (1_000_000_000, "10억"),   // 10억
            (1_350_000_000, "13.5억")  // 13억 5천만
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedPrice, expected, "\(input)의 가격 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    func test_formattedPrice_경계값들() {
        /// - 1억 경계에서의 동작 확인
        XCTAssertEqual(99_999_999.formattedPrice, "9999", "1억 미만은 만원 단위로")
        XCTAssertEqual(100_000_000.formattedPrice, "1억", "정확히 1억은 억 단위로")
        XCTAssertEqual(100_000_001.formattedPrice, "1억", "1억1원은 반올림하여 1억으로 표시")
    }

    func test_formattedPrice_반올림_정확성() {
        /// - 반올림 개선으로 인한 정확성 테스트
        let testCases: [(input: Int, expected: String, description: String)] = [
            (100_000_001, "1억", "1억1원은 1억으로 반올림"),
            (104_999_999, "1억", "1억 4999만원은 1억으로 반올림"),
            (105_000_000, "1.1억", "1억 5천만원은 1.1억으로 반올림"),
            (149_999_999, "1.5억", "1억 4999만원은 1.5억으로 반올림"),
            (150_000_000, "1.5억", "정확히 1.5억"),
            (154_999_999, "1.5억", "1억 5499만원은 1.5억으로 반올림"),
            (155_000_000, "1.6억", "1억 5500만원은 1.6억으로 반올림")
        ]

        for (input, expected, description) in testCases {
            XCTAssertEqual(input.formattedPrice, expected, description)
        }
    }

    // MARK: - Price Formatting with Unit Tests (formattedPriceWithUnit)

    func test_formattedPriceWithUnit_만원_단위() {
        let testCases: [(input: Int, expected: String)] = [
            (0, "0"),
            (10_000, "1만"),        // 1만원
            (50_000, "5만"),        // 5만원
            (500_000, "50만"),      // 50만원
            (9_999_999, "999만")    // 999만원 (천만 미만)
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedPriceWithUnit, expected, "\(input)의 단위 포함 가격 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    func test_formattedPriceWithUnit_억_단위() {
        let testCases: [(input: Int, expected: String)] = [
            (100_000_000, "1억"),      // 1억원
            (150_000_000, "1.5억"),    // 1억 5천만원
            (200_000_000, "2억"),      // 2억원
            (1_000_000_000, "10억"),   // 10억원
            (1_250_000_000, "12.5억")  // 12억 5천만원
        ]

        for (input, expected) in testCases {
            XCTAssertEqual(input.formattedPriceWithUnit, expected, "\(input)의 단위 포함 가격 포맷팅 결과가 '\(expected)'이어야 함")
        }
    }

    func test_formattedPriceWithUnit_특수케이스() {
        /// - 0원
        XCTAssertEqual(0.formattedPriceWithUnit, "0")

        /// - 만원 미만 (현재 구현상 0이 됨)
        XCTAssertEqual(5000.formattedPriceWithUnit, "0", "만원 미만은 0으로 표시")

        /// - 정확한 억 단위
        XCTAssertEqual(300_000_000.formattedPriceWithUnit, "3억", "정확한 억 단위는 소수점 없이")

        /// - 소수점이 있는 억 단위
        XCTAssertEqual(350_000_000.formattedPriceWithUnit, "3.5억", "소수점 있는 억 단위는 .1자리까지")
    }

    func test_formattedPriceWithUnit_경계값_테스트() {
        /// - 천만원 경계 (만원 → 억 전환 지점)
        XCTAssertEqual(99_999_999.formattedPriceWithUnit, "9999만", "1억 미만은 만원 단위")
        XCTAssertEqual(100_000_000.formattedPriceWithUnit, "1억", "1억부터는 억 단위")
    }

    // MARK: - Edge Cases and Error Handling

    func test_formattedPrice_음수_처리() {
        /// - 음수에 대한 처리 확인 (실제 부동산 가격에서는 사용되지 않지만 안전성 확인)
        let negativePrice = -100_000_000
        let result = negativePrice.formattedPrice

        /// - 음수 처리 방식 확인 (현재 구현에 따라)
        print("음수 가격 처리: \(negativePrice) → '\(result)'")
    }

    func test_large_numbers_formatting() {
        /// - 매우 큰 수에 대한 처리 확인
        let largeNumber = Int.max
        let commaResult = largeNumber.formattedWithComma
        let priceResult = largeNumber.formattedPrice
        let unitResult = largeNumber.formattedPriceWithUnit

        /// - 오버플로우 없이 처리되는지 확인
        XCTAssertFalse(commaResult.isEmpty, "매우 큰 수도 콤마 포맷팅 가능해야 함")
        XCTAssertFalse(priceResult.isEmpty, "매우 큰 수도 가격 포맷팅 가능해야 함")
        XCTAssertFalse(unitResult.isEmpty, "매우 큰 수도 단위 포함 포맷팅 가능해야 함")

        print("Large number formatting:")
        print("  Comma: \(commaResult)")
        print("  Price: \(priceResult)")
        print("  Unit: \(unitResult)")
    }
}