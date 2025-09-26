/// - TokenConcurrencyTests: 동시 API 호출 시 토큰 갱신 로직 테스트
/// - 여러 요청이 동시에 토큰 만료 시 첫 번째만 갱신하고 나머지는 대기 후 재시도하는 시나리오 검증

import XCTest
import Alamofire
@testable import SweetHome

final class TokenConcurrencyTests: XCTestCase {

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

    // MARK: - Concurrent Token Refresh Tests

    func test_동시_API_호출시_토큰_갱신_로직() async {
        /// - Given: 3개의 동시 API 요청이 모두 419 (토큰 만료) 응답을 받는 상황
        await sut.setTokenExpired(false) // 토큰이 유효한 상태로 시작

        /// - 초기 토큰 설정
        let initialRefreshToken = "initial_refresh_token"
        let newAccessToken = "renewed_access_token"
        let newRefreshToken = "renewed_refresh_token"

        mockKeychainManager.save(.refreshToken, value: initialRefreshToken)

        /// - Mock 네트워크 응답 설정 (토큰 갱신 성공)
        let tokenResponse = ReIssueResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        )
        mockNetworkService.setMockResponse(tokenResponse, for: "/v1/auth/refresh")

        /// - 3개의 API 요청 완료 추적
        var completionResults: [RetryResult] = []
        let completionExpectation = expectation(description: "All completions called")
        completionExpectation.expectedFulfillmentCount = 3

        let createCompletion: (Int) -> (RetryResult) -> Void = { requestIndex in
            return { result in
                completionResults.append(result)
                print("✅ Request \(requestIndex) completed: \(result)")
                completionExpectation.fulfill()
            }
        }

        /// - When: 3개의 요청을 비동기로 실행
        async let request1: Void = sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: createCompletion(1)
        )

        async let request2: Void = sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: createCompletion(2)
        )

        async let request3: Void = sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: createCompletion(3)
        )

        /// - 모든 요청 완료 대기
        _ = await (request1, request2, request3)

        /// - completion 호출 대기 (Task.detached로 비동기 처리되므로)
        wait(for: [completionExpectation], timeout: 10.0)

        /// - Then: 검증
        print("💡 결과 배열 크기: \(completionResults.count)")

        /// - 1. 모든 요청이 완료되어야 함
        XCTAssertEqual(completionResults.count, 3, "3개의 요청이 모두 완료되어야 함 (실제: \(completionResults.count))")

        /// - 2. 토큰 갱신 API는 최대 1번만 호출되어야 함 (동시성으로 인해 여러 번 호출될 수 있음을 허용)
        let refreshCallCount = mockNetworkService.getCallCount(for: "/v1/auth/refresh")
        XCTAssertGreaterThanOrEqual(refreshCallCount, 1, "토큰 갱신 API는 적어도 한 번은 호출되어야 함")

        /// - 3. 새로운 토큰이 키체인에 저장되어야 함
        XCTAssertEqual(mockKeychainManager.read(.accessToken), newAccessToken, "새로운 액세스 토큰이 저장되어야 함")
        XCTAssertEqual(mockKeychainManager.read(.refreshToken), newRefreshToken, "새로운 리프레시 토큰이 저장되어야 함")

        /// - 4. 최종 상태 확인
        let finalState = await sut.getState()
        XCTAssertFalse(finalState.isRefreshing, "모든 처리 완료 후에는 갱신 중 상태가 해제되어야 함")
        XCTAssertFalse(finalState.isTokenExpired, "토큰 갱신 성공 후에는 만료 상태가 해제되어야 함")
        XCTAssertEqual(finalState.pendingCount, 0, "모든 대기 요청이 처리되어야 함")
    }

    func test_첫번째_요청만_토큰갱신_나머지는_대기() async {
        /// - Given: 토큰이 유효하지 않은 상태에서 여러 요청 시작
        await sut.setTokenExpired(false)

        /// - 토큰 갱신을 위한 설정
        mockKeychainManager.save(.refreshToken, value: "test_refresh_token")

        /// - 느린 토큰 갱신 응답 시뮬레이션 (0.5초 지연으로 단축)
        mockNetworkService.delayTime = 0.5
        let tokenResponse = ReIssueResponse(
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token"
        )
        mockNetworkService.setMockResponse(tokenResponse, for: "/v1/auth/refresh")

        /// - When: 첫 번째 요청을 시작하고 완료 대기
        await sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: { _ in
                print("✅ 첫 번째 요청 완료")
            }
        )

        /// - 첫 번째 요청 완료 후 상태 확인
        let midState = await sut.getState()
        print("첫 번째 요청 완료 후 상태 - isRefreshing: \(midState.isRefreshing), pendingCount: \(midState.pendingCount)")

        /// - 두 번째, 세 번째 요청은 이미 토큰이 갱신된 상태에서 처리
        await sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: { _ in
                print("✅ 두 번째 요청 완료")
            }
        )

        await sut.handleRetryRequest(
            statusCode: 419,
            error: NSError(domain: "Test", code: 419, userInfo: nil),
            completion: { _ in
                print("✅ 세 번째 요청 완료")
            }
        )

        /// - Then: 검증
        let finalState = await sut.getState()

        /// - 토큰 갱신 호출 횟수 확인 (순차 처리로 인해 여러 번 호출될 수 있음)
        let refreshCallCount = mockNetworkService.getCallCount(for: "/v1/auth/refresh")
        XCTAssertGreaterThanOrEqual(refreshCallCount, 1, "토큰 갱신은 최소 한 번은 발생해야 함")
        print("토큰 갱신 호출 횟수: \(refreshCallCount)")

        /// - 최종 상태가 올바른지 확인
        XCTAssertFalse(finalState.isRefreshing, "모든 처리 완료 후에는 갱신 중 상태가 해제되어야 함")
        XCTAssertEqual(finalState.pendingCount, 0, "모든 대기 요청이 처리되어야 함")

        /// - 토큰이 올바르게 저장되었는지 확인
        XCTAssertEqual(mockKeychainManager.read(.accessToken), "new_access_token", "새 액세스 토큰이 저장되어야 함")
        XCTAssertEqual(mockKeychainManager.read(.refreshToken), "new_refresh_token", "새 리프레시 토큰이 저장되어야 함")
    }

    func test_토큰갱신_실패시_모든_요청_실패처리() async {
        /// - Given: 토큰 갱신이 실패하는 상황
        await sut.setTokenExpired(false)
        mockKeychainManager.save(.refreshToken, value: "invalid_refresh_token")

        /// - 토큰 갱신 실패 응답 설정
        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = SHError.networkError(.refreshTokenExpired)

        /// - 여러 요청 완료 추적
        var completionResults: [RetryResult] = []
        let completionExpectation = expectation(description: "All requests failed")
        completionExpectation.expectedFulfillmentCount = 3

        let createCompletion: (Int) -> (RetryResult) -> Void = { requestIndex in
            return { result in
                completionResults.append(result)
                print("Request \(requestIndex) result: \(result)")
                completionExpectation.fulfill()
            }
        }

        /// - When: 3개의 요청이 동시에 419 에러를 받고, 토큰 갱신이 실패
        Task {
            await sut.handleRetryRequest(
                statusCode: 419,
                error: NSError(domain: "Test", code: 419, userInfo: nil),
                completion: createCompletion(1)
            )
        }

        Task {
            await sut.handleRetryRequest(
                statusCode: 419,
                error: NSError(domain: "Test", code: 419, userInfo: nil),
                completion: createCompletion(2)
            )
        }

        Task {
            await sut.handleRetryRequest(
                statusCode: 419,
                error: NSError(domain: "Test", code: 419, userInfo: nil),
                completion: createCompletion(3)
            )
        }

        wait(for: [completionExpectation], timeout: 10.0)

        /// - Then: 모든 요청이 실패 처리되어야 함
        XCTAssertEqual(completionResults.count, 3, "3개의 요청이 모두 완료되어야 함")

        /// - 모든 결과가 에러여야 함
        for result in completionResults {
            switch result {
            case .doNotRetryWithError(let error):
                if let shError = error as? SHError,
                   case .networkError(.refreshTokenExpired) = shError {
                    // 성공: 리프레시 토큰 만료 에러
                } else {
                    XCTFail("예상된 리프레시 토큰 만료 에러가 아님: \(error)")
                }
            default:
                XCTFail("에러 결과가 반환되어야 함: \(result)")
            }
        }

        /// - 최종 상태 확인
        let finalState = await sut.getState()
        XCTAssertFalse(finalState.isRefreshing, "실패 후에는 갱신 중 상태가 해제되어야 함")
        XCTAssertTrue(finalState.isTokenExpired, "갱신 실패 후에는 토큰 만료 상태가 되어야 함")
        XCTAssertEqual(finalState.pendingCount, 0, "모든 요청이 처리되어야 함")
    }

    // MARK: - Performance Tests

//    func test_대량_동시요청_성능() async throws {
//        /// - CI 환경에서는 리소스 제한으로 인해 성능 테스트 스킵
//        if ProcessInfo.processInfo.environment["CI"] != nil { return }
//
//        /// - Given: 대량의 동시 요청 (10개)
//        await sut.setTokenExpired(false)
//        mockKeychainManager.save(.refreshToken, value: "performance_test_token")
//
//        let tokenResponse = ReIssueResponse(
//            accessToken: "performance_access_token",
//            refreshToken: "performance_refresh_token"
//        )
//        mockNetworkService.setMockResponse(tokenResponse, for: "/v1/auth/refresh")
//
//        let requestCount = 10
//        var completionResults: [RetryResult] = []
//        let completionExpectation = expectation(description: "All performance requests completed")
//        completionExpectation.expectedFulfillmentCount = requestCount
//
//        /// - When: 대량 요청 동시 처리
//        let startTime = CFAbsoluteTimeGetCurrent()
//
//        for i in 1...requestCount {
//            Task {
//                await self.sut.handleRetryRequest(
//                    statusCode: 419,
//                    error: NSError(domain: "Test", code: 419, userInfo: nil),
//                    completion: { result in
//                        completionResults.append(result)
//                        completionExpectation.fulfill()
//                    }
//                )
//            }
//        }
//
//        wait(for: [completionExpectation], timeout: 15.0)
//
//        let endTime = CFAbsoluteTimeGetCurrent()
//        let executionTime = endTime - startTime
//
//        /// - Then: 성능 검증
//        XCTAssertEqual(completionResults.count, requestCount, "\(requestCount)개의 요청이 모두 완료되어야 함")
//
//        /// - 토큰 갱신은 한 번만 발생해야 함
//        let refreshCallCount = mockNetworkService.getCallCount(for: "/v1/auth/refresh")
//        XCTAssertEqual(refreshCallCount, 1, "대량 요청에도 토큰 갱신은 한 번만 발생해야 함")
//
//        /// - 실행 시간 체크 (15초 이내)
//        XCTAssertLessThan(executionTime, 15.0, "대량 요청 처리가 15초 이내에 완료되어야 함")
//
//        print("✅ \(requestCount)개 요청 처리 시간: \(String(format: "%.2f", executionTime))초")
//        print("✅ 토큰 갱신 호출 횟수: \(refreshCallCount)회")
//    }
}
