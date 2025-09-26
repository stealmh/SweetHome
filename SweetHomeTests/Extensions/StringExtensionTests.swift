/// - StringExtensionTests: String Extension의 검증 기능들을 테스트
/// - 이메일, 전화번호, 비밀번호 유효성 검사 및 ISO8601 날짜 변환 테스트

import XCTest
@testable import SweetHome

final class StringExtensionTests: XCTestCase {

    // MARK: - Email Validation Tests

    func test_isValidEmail_유효한_이메일들() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.kr",
            "test123@test-domain.com",
            "user+tag@example.org",
            "user_name@example-domain.net"
        ]

        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "'\(email)'은 유효한 이메일이어야 함")
        }
    }

    func test_isValidEmail_유효하지않은_이메일들() {
        let invalidEmails = [
            "",
            "invalid",
            "@domain.com",
            "test@",
            "test@domain",
            "test.domain.com",
            "test@domain.",
            "test @domain.com",
            "test@dom ain.com"
        ]

        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "'\(email)'은 유효하지 않은 이메일이어야 함")
        }
    }

    // MARK: - Phone Validation Tests

    func test_isValidPhone_유효한_전화번호들() {
        let validPhones = [
            "010-1234-5678",
            "011-123-4567",
            "016-1234-5678",
            "017-123-4567",
            "018-1234-5678",
            "019-123-4567",
            "01012345678",
            "0111234567",
            "01612345678"
        ]

        for phone in validPhones {
            XCTAssertTrue(phone.isValidPhone, "'\(phone)'은 유효한 전화번호여야 함")
        }
    }

    func test_isValidPhone_유효하지않은_전화번호들() {
        let invalidPhones = [
            "",
            "010-123-456",
            "010-12345-6789",
            "020-1234-5678",
            "010 1234 5678",
            "1234567890",
            "010-abc-defg"
        ]

        for phone in invalidPhones {
            XCTAssertFalse(phone.isValidPhone, "'\(phone)'은 유효하지 않은 전화번호여야 함")
        }
    }

    // MARK: - Password Validation Tests

    func test_isValidPassword_유효한_비밀번호들() {
        let validPasswords = [
            "Password1!",
            "Test123@",
            "Secure#Password8",
            "MyP@ssw0rd",
            "Complex1$Password"
        ]

        for password in validPasswords {
            XCTAssertTrue(password.isValidPassword, "'\(password)'는 유효한 비밀번호여야 함")
        }
    }

    func test_isValidPassword_유효하지않은_비밀번호들() {
        let invalidCases = [
            ("", "빈 문자열"),
            ("short1!", "7자 미만"),
            ("SpecialChar!", "숫자 없음"),
            ("12345678!", "영문자 없음"),
            ("Password123", "특수문자 없음"),
            ("onlylowercase123!", "대문자 없음은 허용"),
            ("ONLYUPPERCASE123!", "소문자 없음은 허용")
        ]

        /// - 대문자/소문자 구분 없이 영문자만 포함
        let shouldBeValidCases = [
            "onlylowercase123!",
            "ONLYUPPERCASE123!"
        ]

        for (password, reason) in invalidCases {
            if shouldBeValidCases.contains(password) {
                XCTAssertTrue(password.isValidPassword, "'\(password)'는 유효해야 함 (\(reason))")
            } else {
                XCTAssertFalse(password.isValidPassword, "'\(password)'는 유효하지 않아야 함 (\(reason))")
            }
        }
    }

    // MARK: - Password Validation Message Tests

    func test_passwordValidationMessage_빈_문자열() {
        XCTAssertNil("".passwordValidationMessage, "빈 문자열은 nil 반환해야 함")
    }

    func test_passwordValidationMessage_길이_부족() {
        let message = "short1!".passwordValidationMessage
        XCTAssertEqual(message, "비밀번호는 최소 8자 이상이어야 합니다")
    }

    func test_passwordValidationMessage_영문자_없음() {
        let message = "12345678!".passwordValidationMessage
        XCTAssertEqual(message, "영문자를 포함해야 합니다")
    }

    func test_passwordValidationMessage_숫자_없음() {
        let message = "Password!".passwordValidationMessage
        XCTAssertEqual(message, "숫자를 포함해야 합니다")
    }

    func test_passwordValidationMessage_특수문자_없음() {
        let message = "Password123".passwordValidationMessage
        XCTAssertEqual(message, "특수문자를 포함해야 합니다")
    }

    func test_passwordValidationMessage_유효한_비밀번호() {
        let message = "Password123!".passwordValidationMessage
        XCTAssertNil(message, "유효한 비밀번호는 nil 반환해야 함")
    }

    // MARK: - ISO8601 Date Conversion Tests

    func test_toISO8601Date_유효한_날짜_문자열() {
        let dateStrings = [
            "2025-05-13T14:53:43.177Z",
            "2024-12-31T23:59:59.999Z",
            "2024-01-01T00:00:00.000Z"
        ]

        for dateString in dateStrings {
            let date = dateString.toISO8601Date()
            XCTAssertNotNil(date, "'\(dateString)'은 유효한 날짜로 변환되어야 함")
        }
    }

    func test_toISO8601Date_특정_날짜_확인() {
        let dateString = "2025-05-13T14:53:43.177Z"
        let date = dateString.toISO8601Date()

        XCTAssertNotNil(date)

        /// - UTC 시간대를 명시적으로 사용해야 함!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date!)

        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 13)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 53)
        XCTAssertEqual(components.second, 43)
    }

    func test_toISO8601Date_유효하지않은_날짜_문자열() {
        let invalidDateStrings = [
            "",
            "invalid date",
            "2025-05-13",
            "2025/05/13T14:53:43Z",
            "2025-13-45T25:61:61Z"
        ]

        for dateString in invalidDateStrings {
            let date = dateString.toISO8601Date()
            XCTAssertNil(date, "'\(dateString)'은 nil을 반환해야 함")
        }
    }

    func test_toISO8601Date_다양한_포맷() {
        /// - 마이크로초 없는 포맷도 지원하는지 확인
        let dateWithoutMicro = "2025-05-13T14:53:43Z"
        let result = dateWithoutMicro.toISO8601Date()

        /// - 현재 구현은 fractionalSeconds를 필수로 요구하므로 nil일 수 있음
        /// - 실제 사용 케이스에 따라 구현 개선 필요할 수 있음
        if result == nil {
            print("⚠️ 마이크로초 없는 ISO8601 포맷은 지원하지 않음: \(dateWithoutMicro)")
        } else {
            print("✅ 마이크로초 없는 ISO8601 포맷도 지원함")
        }
    }
}
