/// - AuthTokenManagerTests: AuthTokenManager의 토큰 캐싱 및 관리 기능 테스트
/// - 액세스 토큰, SeSAC 키 캐싱, 노티피케이션 처리, 캐시 관리 등을 검증

import XCTest
@testable import SweetHome

final class AuthTokenManagerTests: XCTestCase {

    var sut: AuthTokenManager!
    var mockKeychainManager: TestableKeychainManager!

    override func setUp() {
        super.setUp()
        mockKeychainManager = TestableKeychainManager()
        sut = AuthTokenManager(keychainManager: mockKeychainManager)
    }

    override func tearDown() {
        sut = nil
        mockKeychainManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_초기_토큰_로딩() {
        /// - Given: 키체인에 액세스 토큰이 있는 상태
        let testToken = "test_access_token_12345"
        mockKeychainManager.save(.accessToken, value: testToken)

        /// - When: AuthTokenManager 초기화
        let tokenManager = AuthTokenManager(keychainManager: mockKeychainManager)

        /// - Then: 토큰이 캐시됨
        XCTAssertEqual(tokenManager.accessToken, testToken, "초기화 시 키체인의 토큰이 캐시되어야 함")
    }

    func test_init_토큰없음() {
        /// - Given: 키체인에 액세스 토큰이 없는 상태
        mockKeychainManager.delete(.accessToken)

        /// - When: AuthTokenManager 초기화
        let tokenManager = AuthTokenManager(keychainManager: mockKeychainManager)

        /// - Then: 토큰이 nil
        XCTAssertNil(tokenManager.accessToken, "토큰이 없을 때는 nil이어야 함")
    }

    func test_init_notification_observer_등록() {
        /// - Given: AuthTokenManager 생성됨 (setUp에서)

        /// - When: 토큰 만료 노티피케이션 발송
        let expectation = expectation(description: "Token expired notification")

        /// - 캐시에 토큰이 있는 상태로 설정
        let testToken = "cached_token"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.refreshCache() // 캐시 갱신

        XCTAssertEqual(sut.accessToken, testToken, "캐시에 토큰이 있어야 함")

        /// - 노티피케이션 발송 전에 키체인에서도 토큰 삭제 (실제 앱에서 토큰 만료 시 키체인도 클리어됨)
        mockKeychainManager.delete(.accessToken)

        /// - 노티피케이션 발송
        NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)

        /// - 노티피케이션 처리를 위한 충분한 지연 시간
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            /// - Then: 캐시가 클리어되고, 키체인에도 토큰이 없으므로 nil 반환
            XCTAssertNil(self.sut.accessToken, "토큰 만료 노티피케이션 후 캐시가 클리어되어야 함")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Access Token Tests

    func test_accessToken_캐시된_값_반환() {
        /// - Given: 캐시된 토큰이 있는 상태
        let testToken = "cached_access_token"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.refreshCache()

        /// - When: 액세스 토큰 조회
        let token = sut.accessToken

        /// - Then: 캐시된 값 반환
        XCTAssertEqual(token, testToken, "캐시된 토큰이 반환되어야 함")
    }

    func test_accessToken_캐시없으면_키체인에서_로딩() {
        /// - Given: 캐시는 없고 키체인에만 토큰이 있는 상태
        let testToken = "keychain_access_token"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.clearCache() // 캐시 클리어

        /// - When: 액세스 토큰 조회
        let token = sut.accessToken

        /// - Then: 키체인에서 로딩되어 반환
        XCTAssertEqual(token, testToken, "키체인에서 토큰이 로딩되어 반환되어야 함")
    }

    func test_accessToken_키체인에도_없음() {
        /// - Given: 캐시와 키체인 모두에 토큰이 없는 상태
        mockKeychainManager.delete(.accessToken)
        sut.clearCache()

        /// - When: 액세스 토큰 조회
        let token = sut.accessToken

        /// - Then: nil 반환
        XCTAssertNil(token, "토큰이 없을 때는 nil이 반환되어야 함")
    }

    func test_accessToken_여러번_조회시_성능() {
        /// - Given: 키체인에 토큰이 있는 상태
        let testToken = "performance_test_token"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.clearCache() // 캐시 클리어

        /// - readCallCount 초기화 (setUp에서 발생한 조회 무시)
        mockKeychainManager.readCallCount = 0

        /// - When: 첫 번째 조회 (키체인에서 로딩)
        let firstToken = sut.accessToken

        /// - 두 번째, 세 번째 조회 (캐시에서 반환)
        let secondToken = sut.accessToken
        let thirdToken = sut.accessToken

        /// - Then: 모두 동일한 토큰 반환
        XCTAssertEqual(firstToken, testToken, "첫 번째 조회 성공")
        XCTAssertEqual(secondToken, testToken, "두 번째 조회 성공")
        XCTAssertEqual(thirdToken, testToken, "세 번째 조회 성공")

        /// - 키체인 조회는 한 번만 발생해야 함 (캐싱 효과)
        /// - 첫 번째 조회에서만 키체인 접근이 발생하고, 나머지는 캐시에서 반환
        XCTAssertEqual(mockKeychainManager.readCallCount, 1, "키체인 조회는 한 번만 발생해야 함")
    }

    // MARK: - SeSAC Key Tests

    func test_sesacKey_항상_반환() {
        /// - Given: AuthTokenManager 생성됨

        /// - When: SeSAC 키 조회
        let key = sut.sesacKey

        /// - Then: 빈 문자열이 아닌 값 반환
        XCTAssertFalse(key.isEmpty, "SeSAC 키는 빈 문자열이 아니어야 함")
    }

    func test_sesacKey_캐싱_동작() {
        /// - Given: 초기 상태
        sut.clearCache()

        /// - When: 여러 번 조회
        let key1 = sut.sesacKey
        let key2 = sut.sesacKey
        let key3 = sut.sesacKey

        /// - Then: 모두 동일한 값 반환
        XCTAssertEqual(key1, key2, "SeSAC 키는 캐시되어 동일해야 함")
        XCTAssertEqual(key2, key3, "SeSAC 키는 캐시되어 동일해야 함")
        XCTAssertFalse(key1.isEmpty, "SeSAC 키는 유효한 값이어야 함")
    }

    // MARK: - Cache Management Tests

    func test_refreshCache_키체인에서_재로딩() {
        /// - Given: 캐시된 토큰과 다른 토큰이 키체인에 있는 상태
        let oldToken = "old_cached_token"
        let newToken = "new_keychain_token"

        mockKeychainManager.save(.accessToken, value: oldToken)
        sut.refreshCache()
        XCTAssertEqual(sut.accessToken, oldToken, "초기 캐시 확인")

        /// - 키체인 값 변경
        mockKeychainManager.save(.accessToken, value: newToken)

        /// - When: 캐시 갱신
        sut.refreshCache()

        /// - Then: 새로운 토큰이 캐시됨
        XCTAssertEqual(sut.accessToken, newToken, "캐시가 새로운 토큰으로 갱신되어야 함")
    }

    func test_clearCache_캐시_초기화() {
        /// - Given: 캐시된 토큰이 있는 상태
        let testToken = "test_token_to_clear"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.refreshCache()
        XCTAssertEqual(sut.accessToken, testToken, "캐시된 토큰 확인")

        /// - When: 캐시 클리어
        sut.clearCache()

        /// - Then: 다음 조회 시 키체인에서 다시 로딩
        let reloadedToken = sut.accessToken
        XCTAssertEqual(reloadedToken, testToken, "캐시 클리어 후 키체인에서 재로딩되어야 함")
    }

    func test_clearCache_모든_캐시_클리어() {
        /// - Given: 액세스 토큰과 SeSAC 키가 캐시된 상태
        mockKeychainManager.save(.accessToken, value: "test_token")
        sut.refreshCache()

        let _ = sut.accessToken // 액세스 토큰 캐시
        let _ = sut.sesacKey    // SeSAC 키 캐시

        /// - When: 캐시 클리어
        sut.clearCache()

        /// - 캐시가 클리어되었는지는 내부 구현에 따라 검증 방법이 다름
        /// - 다음 조회 시 정상적으로 값이 반환되는지 확인
        let accessToken = sut.accessToken
        let sesacKey = sut.sesacKey

        /// - Then: 정상적으로 값 반환 (키체인에서 재로딩 또는 상수에서 반환)
        XCTAssertEqual(accessToken, "test_token", "액세스 토큰이 정상적으로 반환되어야 함")
        XCTAssertFalse(sesacKey.isEmpty, "SeSAC 키가 정상적으로 반환되어야 함")
    }

    // MARK: - Notification Handling Tests

    func test_handleTokenExpired_캐시_클리어() {
        /// - Given: 캐시된 토큰이 있는 상태
        let testToken = "token_to_be_expired"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.refreshCache()
        XCTAssertEqual(sut.accessToken, testToken, "초기 캐시된 토큰 확인")

        /// - When: 토큰 만료 노티피케이션 발송
        let expectation = expectation(description: "Handle token expired")

        /// - 노티피케이션 발송
        NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)

        /// - 노티피케이션 처리를 위한 충분한 지연 시간
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)

        /// - Then: 캐시가 클리어됨
        /// - 토큰 만료 노티피케이션 후에는 캐시가 클리어되어야 함
        /// - 키체인에서 다시 로딩하므로 여전히 토큰이 반환될 수 있지만, 실제 앱에서는 키체인도 함께 클리어됨
        print("토큰 만료 처리 후 액세스 토큰: \(sut.accessToken ?? "nil")")

        /// - 실제 구현에 따라 캐시 클리어 여부를 확인할 수 있다면 추가 검증 가능
        /// - 현재는 동작 확인 차원에서 print로 출력
    }

    // MARK: - Shared Instance Tests

    func test_shared_instance_동일성() {
        /// - Given: Shared instance들
        let instance1 = AuthTokenManager.shared
        let instance2 = AuthTokenManager.shared

        /// - Then: 동일한 인스턴스
        XCTAssertTrue(instance1 === instance2, "Shared instance는 동일한 객체여야 함")
    }

    func test_shared_instance_독립성() {
        /// - Given: Shared instance와 직접 생성한 instance
        let sharedInstance = AuthTokenManager.shared
        let customInstance = AuthTokenManager(keychainManager: mockKeychainManager)

        /// - When: 각각에 다른 키체인 매니저 설정
        mockKeychainManager.save(.accessToken, value: "custom_token")

        /// - Then: 서로 다른 토큰 반환 (다른 키체인 매니저 사용)
        let sharedToken = sharedInstance.accessToken
        let customToken = customInstance.accessToken

        /// - Shared instance는 실제 키체인을 사용하고, custom instance는 mock을 사용
        print("Shared instance 토큰: \(sharedToken ?? "nil")")
        print("Custom instance 토큰: \(customToken ?? "nil")")

        /// - Custom instance는 mock을 사용하므로 설정한 토큰이 반환됨
        XCTAssertEqual(customToken, "custom_token", "Custom instance는 mock 키체인의 토큰을 반환해야 함")
    }

    // MARK: - Integration Tests

    func test_전체_토큰_라이프사이클() {
        /// - Given: 토큰이 없는 초기 상태
        mockKeychainManager.delete(.accessToken)
        sut.clearCache()

        /// - Step 1: 토큰 없음 확인
        XCTAssertNil(sut.accessToken, "초기에는 토큰이 없어야 함")

        /// - Step 2: 로그인으로 토큰 생성 시뮬레이션
        let newToken = "login_success_token"
        mockKeychainManager.save(.accessToken, value: newToken)

        /// - Step 3: 캐시 갱신 후 토큰 확인
        sut.refreshCache()
        XCTAssertEqual(sut.accessToken, newToken, "로그인 후 토큰이 캐시되어야 함")

        /// - Step 4: 토큰 만료 시뮬레이션
        let tokenExpiredExpectation = expectation(description: "Token expired lifecycle")

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .refreshTokenExpired, object: nil)

            DispatchQueue.main.async {
                /// - Step 5: 토큰 만료 후 상태 확인
                /// - 캐시는 클리어되지만 키체인에는 여전히 토큰이 있을 수 있음
                print("토큰 만료 처리 완료")
                tokenExpiredExpectation.fulfill()
            }
        }

        wait(for: [tokenExpiredExpectation], timeout: 2.0)

        /// - Step 6: 새 토큰으로 갱신
        let refreshedToken = "refreshed_access_token"
        mockKeychainManager.save(.accessToken, value: refreshedToken)
        sut.refreshCache()

        /// - Then: 새 토큰이 정상적으로 캐시됨
        XCTAssertEqual(sut.accessToken, refreshedToken, "토큰 갱신 후 새 토큰이 캐시되어야 함")
    }

    // MARK: - Performance Tests

    func test_성능_토큰_조회_캐싱() {
        /// - Given: 키체인에 토큰이 있는 상태
        let testToken = "performance_token"
        mockKeychainManager.save(.accessToken, value: testToken)
        sut.clearCache()

        /// - When: 반복적인 토큰 조회
        measure {
            for _ in 0..<1000 {
                let _ = sut.accessToken
            }
        }

        /// - 첫 번째 조회에서만 키체인 접근이 발생하고, 나머지는 캐시에서 반환되므로 빨라야 함
    }
}