/// - TokenManagerTests: TokenManager의 토큰 갱신 및 상태 관리 기능 테스트
/// - 상태 관리, 토큰 갱신, 요청 재시도, 에러 처리 등을 검증

import XCTest
import Alamofire
@testable import SweetHome

final class TokenManagerTests: XCTestCase {

    var sut: TokenManager!
    var mockKeychainManager: TestableKeychainManager!
    var mockNetworkService: MockNetworkService!

    override func setUp() async throws {
        try await super.setUp()
        mockKeychainManager = TestableKeychainManager()
        mockNetworkService = MockNetworkService()
        sut = TokenManager(
            keychainManager: mockKeychainManager,
            refreshNetworkService: mockNetworkService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockKeychainManager = nil
        mockNetworkService = nil
        try await super.tearDown()
    }

    // MARK: - State Management Tests

    func test_getState_초기상태() async {
        /// - Given: 초기화된 TokenManager

        /// - When: 상태 조회
        let state = await sut.getState()

        /// - Then: 초기 상태 확인
        XCTAssertFalse(state.isRefreshing, "초기 상태에서 갱신 중이면 안됨")
        XCTAssertFalse(state.isTokenExpired, "초기 상태에서 만료되면 안됨")
        XCTAssertEqual(state.pendingCount, 0, "초기 상태에서 대기 요청이 없어야 함")
    }

    func test_setTokenExpired_상태변경() async {
        /// - Given: 초기 상태

        /// - When: 토큰 만료 상태 설정
        await sut.setTokenExpired(true)

        /// - Then: 만료 상태가 변경됨
        let isExpired = await sut.isExpired()
        XCTAssertTrue(isExpired, "토큰이 만료 상태로 설정되어야 함")

        /// - When: 토큰 만료 상태 해제
        await sut.setTokenExpired(false)

        /// - Then: 만료 상태가 해제됨
        let isNotExpired = await sut.isExpired()
        XCTAssertFalse(isNotExpired, "토큰 만료 상태가 해제되어야 함")
    }

    func test_startRefresh_정상케이스() async {
        /// - Given: 초기 상태

        /// - When: 갱신 시작
        let success = await sut.startRefresh()

        /// - Then: 갱신이 시작됨
        XCTAssertTrue(success, "갱신 시작이 성공해야 함")

        let state = await sut.getState()
        XCTAssertTrue(state.isRefreshing, "갱신 중 상태가 되어야 함")
    }

    func test_startRefresh_이미_갱신중인_경우() async {
        /// - Given: 이미 갱신 중인 상태
        let _ = await sut.startRefresh()

        /// - When: 다시 갱신 시작 시도
        let secondAttempt = await sut.startRefresh()

        /// - Then: 두 번째 시도는 실패
        XCTAssertFalse(secondAttempt, "이미 갱신 중일 때는 시작할 수 없어야 함")
    }

    func test_startRefresh_토큰_만료된_경우() async {
        /// - Given: 토큰이 만료된 상태
        await sut.setTokenExpired(true)

        /// - When: 갱신 시작 시도
        let success = await sut.startRefresh()

        /// - Then: 갱신 시작 실패
        XCTAssertFalse(success, "토큰이 만료되었을 때는 갱신을 시작할 수 없어야 함")
    }

    // MARK: - Pending Requests Tests

    func test_addPendingRequest_요청추가() async {
        /// - Given: 초기 상태
        var callbackExecuted = false
        let completion: (RetryResult) -> Void = { _ in
            callbackExecuted = true
        }

        /// - When: 대기 요청 추가
        await sut.addPendingRequest(completion)

        /// - Then: 대기 요청 개수 증가
        let state = await sut.getState()
        XCTAssertEqual(state.pendingCount, 1, "대기 요청이 1개 추가되어야 함")
    }

    func test_finishRefresh_성공시_대기요청_처리() async {
        /// - Given: 갱신 중이고 대기 요청이 있는 상태
        let _ = await sut.startRefresh()

        var completionResults: [RetryResult] = []
        let completion1: (RetryResult) -> Void = { result in
            completionResults.append(result)
        }
        let completion2: (RetryResult) -> Void = { result in
            completionResults.append(result)
        }

        await sut.addPendingRequest(completion1)
        await sut.addPendingRequest(completion2)

        /// - When: 갱신 완료 (성공)
        let completions = await sut.finishRefresh(success: true)

        /// - Then: 상태가 초기화되고 완료 핸들러들이 반환됨
        let state = await sut.getState()
        XCTAssertFalse(state.isRefreshing, "갱신 완료 후 갱신 중 상태가 해제되어야 함")
        XCTAssertFalse(state.isTokenExpired, "성공 시 토큰 만료 상태가 해제되어야 함")
        XCTAssertEqual(state.pendingCount, 0, "대기 요청이 모두 처리되어야 함")
        XCTAssertEqual(completions.count, 2, "2개의 완료 핸들러가 반환되어야 함")
    }

    func test_finishRefresh_실패시_토큰상태_유지() async {
        /// - Given: 토큰이 만료된 상태에서 갱신 시작
        await sut.setTokenExpired(true)
        let refreshStarted = await sut.startRefresh()

        /// - 토큰이 만료된 상태에서는 갱신이 시작되지 않으므로, 수동으로 갱신 상태 설정
        if !refreshStarted {
            // 테스트를 위해 토큰 만료 상태를 임시로 해제하고 갱신 시작
            await sut.setTokenExpired(false)
            let _ = await sut.startRefresh()
            // 다시 토큰 만료 상태로 설정 (실제 갱신 실패 시나리오)
            await sut.setTokenExpired(true)
        }

        /// - When: 갱신 실패로 완료
        let _ = await sut.finishRefresh(success: false)

        /// - Then: 토큰 만료 상태가 그대로 유지됨
        let state = await sut.getState()
        XCTAssertFalse(state.isRefreshing, "갱신 완료 후 갱신 중 상태가 해제되어야 함")
        XCTAssertTrue(state.isTokenExpired, "실패 시 토큰 만료 상태가 유지되어야 함")
    }

    // MARK: - Request Handling Tests

    func test_addAccessTokenToRequest_토큰있음() async {
        /// - Given: 키체인에 액세스 토큰이 있는 상태
        let testToken = "test_access_token_12345"
        mockKeychainManager.save(.accessToken, value: testToken)

        let originalRequest = URLRequest(url: URL(string: "https://api.test.com/data")!)

        /// - When: 요청에 토큰 추가
        let adaptedRequest = await sut.addAccessTokenToRequest(originalRequest)

        /// - Then: Authorization 헤더가 추가됨
        XCTAssertEqual(
            adaptedRequest.value(forHTTPHeaderField: "Authorization"),
            testToken,
            "Authorization 헤더에 액세스 토큰이 추가되어야 함"
        )
    }

    func test_addAccessTokenToRequest_토큰없음() async {
        /// - Given: 키체인에 액세스 토큰이 없는 상태
        mockKeychainManager.delete(.accessToken)

        let originalRequest = URLRequest(url: URL(string: "https://api.test.com/data")!)

        /// - When: 요청에 토큰 추가 시도
        let adaptedRequest = await sut.addAccessTokenToRequest(originalRequest)

        /// - Then: Authorization 헤더가 추가되지 않음
        XCTAssertNil(
            adaptedRequest.value(forHTTPHeaderField: "Authorization"),
            "토큰이 없을 때는 Authorization 헤더가 추가되지 않아야 함"
        )
    }

    // MARK: - Error Handling Tests

    func test_handleRetryRequest_419_토큰갱신() async {
        /// - Given: 419 상태 코드 (액세스 토큰 만료)
        let error = NSError(domain: "Test", code: 419, userInfo: nil)
        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry completion")

        let completion: (RetryResult) -> Void = { result in
            retryResult = result
            expectation.fulfill()
        }

        /// - 토큰 갱신을 위한 Mock 설정
        mockKeychainManager.save(.refreshToken, value: "test_refresh_token")

        /// - When: 재시도 처리
        await sut.handleRetryRequest(statusCode: 419, error: error, completion: completion)

        wait(for: [expectation], timeout: 5.0)

        /// - Then: 토큰 갱신 프로세스가 처리됨
        /// - 실제 네트워크 서비스를 사용하므로 실패할 수 있지만, 프로세스 자체는 진행되어야 함
        XCTAssertNotNil(retryResult, "재시도 결과가 반환되어야 함")

        /// - 최종 상태 확인 (갱신 완료 후)
        let finalState = await sut.getState()
        XCTAssertFalse(finalState.isRefreshing, "처리 완료 후에는 갱신 중 상태가 해제되어야 함")
        XCTAssertEqual(finalState.pendingCount, 0, "처리 완료 후에는 대기 요청이 없어야 함")
    }

    func test_handleRetryRequest_401_토큰만료() async {
        /// - Given: 401 상태 코드 (리프레시 토큰 만료)
        let error = NSError(domain: "Test", code: 401, userInfo: nil)
        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry completion")

        let completion: (RetryResult) -> Void = { result in
            retryResult = result
            expectation.fulfill()
        }

        /// - When: 재시도 처리
        await sut.handleRetryRequest(statusCode: 401, error: error, completion: completion)

        wait(for: [expectation], timeout: 2.0)

        /// - Then: 재시도하지 않고 토큰 만료 에러 반환
        switch retryResult {
        case .doNotRetryWithError(let resultError):
            if let shError = resultError as? SHError,
               case .networkError(.refreshTokenExpired) = shError {
                // 성공
            } else {
                XCTFail("리프레시 토큰 만료 에러가 반환되어야 함")
            }
        default:
            XCTFail("재시도하지 않고 에러가 반환되어야 함")
        }

        /// - 토큰 만료 상태 확인
        let isExpired = await sut.isExpired()
        XCTAssertTrue(isExpired, "토큰이 만료 상태로 설정되어야 함")
    }

    func test_handleRetryRequest_기타_에러() async {
        /// - Given: 기타 상태 코드 (500)
        let error = NSError(domain: "Test", code: 500, userInfo: nil)
        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry completion")

        let completion: (RetryResult) -> Void = { result in
            retryResult = result
            expectation.fulfill()
        }

        /// - When: 재시도 처리
        await sut.handleRetryRequest(statusCode: 500, error: error, completion: completion)

        wait(for: [expectation], timeout: 1.0)

        /// - Then: 재시도하지 않고 원래 에러 반환
        switch retryResult {
        case .doNotRetryWithError(let resultError):
            XCTAssertEqual((resultError as NSError).code, 500, "원래 에러가 그대로 반환되어야 함")
        default:
            XCTFail("재시도하지 않고 에러가 반환되어야 함")
        }
    }

    // MARK: - Cancel Tests

    func test_cancelAllRequests() async {
        /// - Given: 갱신 중이고 대기 요청이 있는 상태
        await sut.startRefresh()

        let completion1: (RetryResult) -> Void = { _ in }
        let completion2: (RetryResult) -> Void = { _ in }
        await sut.addPendingRequest(completion1)
        await sut.addPendingRequest(completion2)

        /// - When: 모든 요청 취소
        let cancelledCompletions = await sut.cancelAllRequests()

        /// - Then: 상태가 초기화되고 완료 핸들러들이 반환됨
        let state = await sut.getState()
        XCTAssertFalse(state.isRefreshing, "취소 후 갱신 중 상태가 해제되어야 함")
        XCTAssertEqual(state.pendingCount, 0, "취소 후 대기 요청이 모두 제거되어야 함")
        XCTAssertEqual(cancelledCompletions.count, 2, "2개의 완료 핸들러가 반환되어야 함")
    }

    // MARK: - Integration Tests

    func test_tokenRefresh_전체플로우() async {
        /// - Given: 토큰 갱신이 필요한 상황
        let refreshToken = "test_refresh_token"
        
        let newAccessToken = "new_access_token"
        let newRefreshToken = "new_refresh_token"

        mockKeychainManager.save(.refreshToken, value: refreshToken)
        
        /// - Mock 네트워크 응답 설정
        let tokenResponse = ReIssueResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        )
        mockNetworkService.setMockResponse(tokenResponse, for: "/v1/auth/refresh")

        var completionResults: [RetryResult] = []
        let completion: (RetryResult) -> Void = { result in
            completionResults.append(result)
        }

        /// - When: 토큰 갱신 처리
        await sut.handleTokenRefresh(
            completion: completion,
            keychainManager: mockKeychainManager,
            refreshNetworkService: mockNetworkService
        )

        /// - 비동기 처리 대기
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기

        /// - Then: 새 토큰들이 저장되고 재시도됨
        XCTAssertEqual(mockKeychainManager.read(.accessToken), newAccessToken)
        XCTAssertEqual(mockKeychainManager.read(.refreshToken), newRefreshToken)

        /// - 상태 확인
        let state = await sut.getState()
        XCTAssertFalse(state.isRefreshing, "갱신 완료 후 갱신 중 상태가 해제되어야 함")
        XCTAssertFalse(state.isTokenExpired, "갱신 성공 후 만료 상태가 해제되어야 함")
    }

    // MARK: - Edge Cases

    func test_tokenRefresh_리프레시토큰_없음() async {
        /// - Given: 리프레시 토큰이 없는 상태
        mockKeychainManager.delete(.refreshToken)

        var completionResults: [RetryResult] = []
        let completion: (RetryResult) -> Void = { result in
            completionResults.append(result)
        }

        /// - When: 토큰 갱신 시도
        await sut.handleTokenRefresh(
            completion: completion,
            keychainManager: mockKeychainManager,
            refreshNetworkService: mockNetworkService
        )

        /// - 비동기 처리 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        /// - Then: 갱신 실패 처리
        XCTAssertFalse(completionResults.isEmpty, "완료 핸들러가 호출되어야 함")

        let state = await sut.getState()
        XCTAssertFalse(state.isRefreshing, "갱신 실패 후 갱신 중 상태가 해제되어야 함")
    }
}

// MARK: - Mock Classes

/// - 테스트용 KeychainManager
/// - 호출 횟수 추적 기능이 추가된 MockKeychainManager
class TestableKeychainManager: KeyChainManagerProtocol {
    private var storage: [KeyChainKey: String] = [:]
    var readCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0

    func contains(_ key: KeyChainKey) -> Bool {
        return storage[key] != nil
    }

    func read(_ key: KeyChainKey) -> String? {
        readCallCount += 1
        return storage[key]
    }

    func save(_ key: KeyChainKey, value: String) {
        saveCallCount += 1
        storage[key] = value
    }

    func delete(_ key: KeyChainKey) {
        deleteCallCount += 1
        storage.removeValue(forKey: key)
    }

    func deleteAll() {
        deleteCallCount += 1
        storage.removeAll()
    }
}
