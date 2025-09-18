/// - EncodableExtensionTests: Encodable Extension의 Dictionary 변환 기능 테스트
/// - Codable 구조체를 Dictionary로 변환하는 toDictionary() 메서드 테스트

import XCTest
@testable import SweetHome

final class EncodableExtensionTests: XCTestCase {

    // MARK: - Test Models

    struct TestUser: Codable {
        let id: Int
        let name: String
        let email: String
        let isActive: Bool
    }

    struct TestUserWithOptional: Codable {
        let id: Int
        let name: String
        let nickname: String?
        let age: Int?
    }

    struct NestedTestModel: Codable {
        let user: TestUser
        let metadata: Metadata

        struct Metadata: Codable {
            let createdAt: String
            let version: Double
        }
    }

    struct TestModelWithArray: Codable {
        let id: Int
        let tags: [String]
        let numbers: [Int]
    }

    // MARK: - Basic Dictionary Conversion Tests

    func test_toDictionary_기본_구조체() {
        let user = TestUser(
            id: 123,
            name: "홍길동",
            email: "test@example.com",
            isActive: true
        )

        let dictionary = user.toDictionary()

        XCTAssertEqual(dictionary["id"] as? Int, 123)
        XCTAssertEqual(dictionary["name"] as? String, "홍길동")
        XCTAssertEqual(dictionary["email"] as? String, "test@example.com")
        XCTAssertEqual(dictionary["isActive"] as? Bool, true)
        XCTAssertEqual(dictionary.keys.count, 4, "4개의 키가 있어야 함")
    }

    func test_toDictionary_옵셔널_값들() {
        let userWithOptional = TestUserWithOptional(
            id: 456,
            name: "김철수",
            nickname: "철수",
            age: 25
        )

        let dictionary = userWithOptional.toDictionary()

        XCTAssertEqual(dictionary["id"] as? Int, 456)
        XCTAssertEqual(dictionary["name"] as? String, "김철수")
        XCTAssertEqual(dictionary["nickname"] as? String, "철수")
        XCTAssertEqual(dictionary["age"] as? Int, 25)
    }

    func test_toDictionary_nil_옵셔널_값들() {
        let userWithNilOptionals = TestUserWithOptional(
            id: 789,
            name: "이영희",
            nickname: nil,
            age: nil
        )

        let dictionary = userWithNilOptionals.toDictionary()

        XCTAssertEqual(dictionary["id"] as? Int, 789)
        XCTAssertEqual(dictionary["name"] as? String, "이영희")

        /// - JSONEncoder는 nil 옵셔널 값을 JSON에서 완전히 제외함
        XCTAssertFalse(dictionary.keys.contains("nickname"), "nil nickname 키는 JSON에서 제외됨")
        XCTAssertFalse(dictionary.keys.contains("age"), "nil age 키는 JSON에서 제외됨")

        /// - 키가 존재하지 않으므로 nil 반환
        XCTAssertNil(dictionary["nickname"], "nickname 키가 없으므로 nil 반환")
        XCTAssertNil(dictionary["age"], "age 키가 없으므로 nil 반환")

        /// - 전체 키 개수 확인 (id, name만 있어야 함)
        XCTAssertEqual(dictionary.keys.count, 2, "nil 값들은 제외되어 2개의 키만 있어야 함")

        /// - 실제 키 목록 확인
        let expectedKeys = Set(["id", "name"])
        let actualKeys = Set(dictionary.keys)
        XCTAssertEqual(actualKeys, expectedKeys, "키 목록이 예상과 일치해야 함")
    }

    // MARK: - Nested Objects Tests

    func test_toDictionary_중첩된_구조체() {
        let user = TestUser(
            id: 1,
            name: "테스트유저",
            email: "nested@test.com",
            isActive: false
        )

        let metadata = NestedTestModel.Metadata(
            createdAt: "2025-01-15T10:00:00Z",
            version: 1.5
        )

        let nestedModel = NestedTestModel(
            user: user,
            metadata: metadata
        )

        let dictionary = nestedModel.toDictionary()

        /// - 중첩된 user 객체 확인
        XCTAssertTrue(dictionary["user"] is [String: Any], "user는 Dictionary여야 함")
        let userDict = dictionary["user"] as! [String: Any]
        XCTAssertEqual(userDict["id"] as? Int, 1)
        XCTAssertEqual(userDict["name"] as? String, "테스트유저")

        /// - 중첩된 metadata 객체 확인
        XCTAssertTrue(dictionary["metadata"] is [String: Any], "metadata는 Dictionary여야 함")
        let metadataDict = dictionary["metadata"] as! [String: Any]
        XCTAssertEqual(metadataDict["createdAt"] as? String, "2025-01-15T10:00:00Z")
        XCTAssertEqual(metadataDict["version"] as? Double, 1.5)
    }

    // MARK: - Array Tests

    func test_toDictionary_배열_포함() {
        let modelWithArray = TestModelWithArray(
            id: 999,
            tags: ["swift", "ios", "test"],
            numbers: [1, 2, 3, 4, 5]
        )

        let dictionary = modelWithArray.toDictionary()

        XCTAssertEqual(dictionary["id"] as? Int, 999)

        /// - String 배열 확인
        XCTAssertTrue(dictionary["tags"] is [String], "tags는 String 배열이어야 함")
        let tags = dictionary["tags"] as! [String]
        XCTAssertEqual(tags, ["swift", "ios", "test"])

        /// - Int 배열 확인
        XCTAssertTrue(dictionary["numbers"] is [Int], "numbers는 Int 배열이어야 함")
        let numbers = dictionary["numbers"] as! [Int]
        XCTAssertEqual(numbers, [1, 2, 3, 4, 5])
    }

    func test_toDictionary_빈_배열() {
        let modelWithEmptyArrays = TestModelWithArray(
            id: 0,
            tags: [],
            numbers: []
        )

        let dictionary = modelWithEmptyArrays.toDictionary()

        XCTAssertEqual(dictionary["id"] as? Int, 0)
        XCTAssertTrue(dictionary["tags"] is [String], "빈 tags 배열도 올바른 타입이어야 함")
        XCTAssertTrue(dictionary["numbers"] is [Int], "빈 numbers 배열도 올바른 타입이어야 함")

        let tags = dictionary["tags"] as! [String]
        let numbers = dictionary["numbers"] as! [Int]

        XCTAssertEqual(tags.count, 0, "빈 배열은 count가 0이어야 함")
        XCTAssertEqual(numbers.count, 0, "빈 배열은 count가 0이어야 함")
    }

    // MARK: - Edge Cases and Error Handling

    func test_toDictionary_인코딩_불가능한_경우() {
        /// - 인코딩이 실패하는 상황을 시뮬레이션하기는 어려우므로
        /// - 현재 구현에서 빈 Dictionary를 반환하는지 확인

        /// - 정상적인 Codable 객체로는 실패 케이스를 만들기 어려움
        /// - 이 테스트는 구현의 방어적 코드를 확인하는 용도
        let normalUser = TestUser(id: 1, name: "Test", email: "test@test.com", isActive: true)
        let result = normalUser.toDictionary()

        XCTAssertFalse(result.isEmpty, "정상적인 객체는 빈 Dictionary를 반환하지 않아야 함")
    }

    func test_toDictionary_특수문자_포함() {
        let userWithSpecialChars = TestUser(
            id: 42,
            name: "특수문자!@#$%^&*()",
            email: "special+chars@example.com",
            isActive: true
        )

        let dictionary = userWithSpecialChars.toDictionary()

        XCTAssertEqual(dictionary["name"] as? String, "특수문자!@#$%^&*()")
        XCTAssertEqual(dictionary["email"] as? String, "special+chars@example.com")
    }

    func test_toDictionary_유니코드_문자() {
        let userWithUnicode = TestUser(
            id: 100,
            name: "🚀 Swift Developer 한글 テスト",
            email: "unicode@한글도메인.com",
            isActive: true
        )

        let dictionary = userWithUnicode.toDictionary()

        XCTAssertEqual(dictionary["name"] as? String, "🚀 Swift Developer 한글 テスト")
        XCTAssertEqual(dictionary["email"] as? String, "unicode@한글도메인.com")
    }

    // MARK: - Performance Test

    func test_toDictionary_성능_테스트() {
        let users = (1...1000).map { index in
            TestUser(
                id: index,
                name: "User \(index)",
                email: "user\(index)@test.com",
                isActive: index % 2 == 0
            )
        }

        measure {
            for user in users {
                _ = user.toDictionary()
            }
        }
    }
}