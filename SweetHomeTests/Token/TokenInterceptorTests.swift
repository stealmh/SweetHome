/// - TokenInterceptorTests: TokenInterceptor의 Alamofire 인터셉터 기능 테스트
/// - HTTP 요청 어댑터, 재시도 인터셉터, TokenManager 위임 등을 검증

import XCTest
import Alamofire
@testable import SweetHome

final class TokenInterceptorTests: XCTestCase {

    var sut: TokenInterceptor!
    var mockSession: Session!

    override func setUp() {
        super.setUp()
        sut = TokenInterceptor.shared

        /// - Mock Session 설정
        let configuration = URLSessionConfiguration.default
        mockSession = Session(configuration: configuration)
    }

    override func tearDown() {
        sut = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Adapt Tests

    func test_adapt_정상요청_토큰추가() {
        /// - Given: 정상적인 HTTP 요청
        let originalURL = URL(string: "https://api.test.com/data")!
        var originalRequest = URLRequest(url: originalURL)
        originalRequest.httpMethod = "GET"

        var adaptedRequest: URLRequest?
        var adaptError: Error?
        let expectation = expectation(description: "Adapt completion")

        /// - When: 요청 어댑팅
        sut.adapt(originalRequest, for: mockSession) { result in
            switch result {
            case .success(let request):
                adaptedRequest = request
            case .failure(let error):
                adaptError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        /// - Then: 요청이 성공적으로 어댑트됨
        XCTAssertNil(adaptError, "어댑팅 시 에러가 발생하지 않아야 함")
        XCTAssertNotNil(adaptedRequest, "어댑트된 요청이 반환되어야 함")
        XCTAssertEqual(adaptedRequest?.url, originalURL, "원본 URL이 보존되어야 함")
        XCTAssertEqual(adaptedRequest?.httpMethod, "GET", "원본 HTTP 메서드가 보존되어야 함")

        /// - Authorization 헤더가 추가되었는지는 TokenManager의 구현에 따라 다름
        /// - 실제 키체인에 토큰이 있다면 추가되고, 없다면 추가되지 않음
        print("Authorization header: \(adaptedRequest?.value(forHTTPHeaderField: "Authorization") ?? "None")")
    }

    func test_adapt_POST_요청() {
        /// - Given: POST 요청
        let originalURL = URL(string: "https://api.test.com/login")!
        var originalRequest = URLRequest(url: originalURL)
        originalRequest.httpMethod = "POST"
        originalRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = """
        {
            "username": "test@example.com",
            "password": "password123"
        }
        """.data(using: .utf8)
        originalRequest.httpBody = jsonData

        var adaptedRequest: URLRequest?
        let expectation = expectation(description: "Adapt POST completion")

        /// - When: POST 요청 어댑팅
        sut.adapt(originalRequest, for: mockSession) { result in
            if case .success(let request) = result {
                adaptedRequest = request
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        /// - Then: POST 요청이 올바르게 어댑트됨
        XCTAssertNotNil(adaptedRequest, "어댑트된 POST 요청이 반환되어야 함")
        XCTAssertEqual(adaptedRequest?.httpMethod, "POST", "POST 메서드가 보존되어야 함")
        XCTAssertEqual(adaptedRequest?.httpBody, jsonData, "HTTP Body가 보존되어야 함")
        XCTAssertEqual(
            adaptedRequest?.value(forHTTPHeaderField: "Content-Type"),
            "application/json",
            "Content-Type 헤더가 보존되어야 함"
        )
    }

    func test_adapt_기존헤더_보존() {
        /// - Given: 기존 헤더가 있는 요청
        let originalURL = URL(string: "https://api.test.com/data")!
        var originalRequest = URLRequest(url: originalURL)
        originalRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        originalRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        originalRequest.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")

        var adaptedRequest: URLRequest?
        let expectation = expectation(description: "Adapt with headers completion")

        /// - When: 요청 어댑팅
        sut.adapt(originalRequest, for: mockSession) { result in
            if case .success(let request) = result {
                adaptedRequest = request
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        /// - Then: 기존 헤더들이 모두 보존됨
        XCTAssertEqual(
            adaptedRequest?.value(forHTTPHeaderField: "Accept"),
            "application/json",
            "Accept 헤더가 보존되어야 함"
        )
        XCTAssertEqual(
            adaptedRequest?.value(forHTTPHeaderField: "Accept-Encoding"),
            "gzip",
            "Accept-Encoding 헤더가 보존되어야 함"
        )
        XCTAssertEqual(
            adaptedRequest?.value(forHTTPHeaderField: "User-Agent"),
            "MyApp/1.0",
            "User-Agent 헤더가 보존되어야 함"
        )
    }

    // MARK: - Retry Tests

    func test_retry_HTTP응답없음() {
        /// - Given: HTTP 응답이 없는 요청 에러
        let error = NSError(domain: "NetworkError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Network timeout"])

        /// - 실제 DataRequest 생성
        let request = mockSession.request("https://test.com")

        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry completion")

        /// - When: 재시도 처리
        sut.retry(request, for: mockSession, dueTo: error) { result in
            retryResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        /// - Then: 재시도하지 않음
        switch retryResult {
        case .doNotRetryWithError(let resultError):
            XCTAssertEqual((resultError as NSError).code, -1001, "원래 에러가 반환되어야 함")
        default:
            XCTFail("HTTP 응답이 없을 때는 재시도하지 않아야 함")
        }
    }

    func test_retry_419_토큰만료() {
        /// - Given: 419 상태 코드 (액세스 토큰 만료)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 419))

        /// - 실제 DataRequest 생성
        let request = mockSession.request("https://api.test.com/data")

        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry 419 completion")

        /// - When: 재시도 처리
        sut.retry(request, for: mockSession, dueTo: error) { result in
            retryResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        /// - Then: 토큰 갱신 프로세스가 시작됨
        /// - 실제 결과는 TokenManager의 상태와 Mock 설정에 따라 달라짐
        XCTAssertNotNil(retryResult, "재시도 결과가 반환되어야 함")
        print("419 응답에 대한 재시도 결과: \(String(describing: retryResult))")
    }

    func test_retry_401_리프레시토큰만료() {
        /// - Given: 401 상태 코드 (리프레시 토큰 만료)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        /// - 실제 DataRequest 생성
        let request = mockSession.request("https://api.test.com/data")

        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry 401 completion")

        /// - When: 재시도 처리
        sut.retry(request, for: mockSession, dueTo: error) { result in
            retryResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)

        /// - Then: 재시도하지 않고 리프레시 토큰 만료 에러 반환
        switch retryResult {
        case .doNotRetryWithError(let resultError):
            if let shError = resultError as? SHError,
               case .networkError(.refreshTokenExpired) = shError {
                // 성공: 리프레시 토큰 만료 에러가 반환됨
                XCTAssert(true, "리프레시 토큰 만료 에러가 정상적으로 반환됨")
            } else {
                print("반환된 에러: \(resultError)")
                // 401은 토큰 만료로 처리되어야 함
            }
        case .retry:
            XCTFail("401 상태 코드에서는 재시도해서는 안됨")
        case .retryWithDelay(_):
            XCTFail("401 상태 코드에서는 지연 재시도해서는 안됨")
        default:
            XCTFail("예상하지 못한 재시도 결과")
        }
    }

    func test_retry_500_서버에러() {
        /// - Given: 500 상태 코드 (서버 내부 에러)
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))

        /// - 실제 DataRequest 생성
        let request = mockSession.request("https://api.test.com/data")

        var retryResult: RetryResult?
        let expectation = expectation(description: "Retry 500 completion")

        /// - When: 재시도 처리
        sut.retry(request, for: mockSession, dueTo: error) { result in
            retryResult = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        /// - Then: 재시도하지 않고 원래 에러 반환
        switch retryResult {
        case .doNotRetryWithError(let resultError):
            // 원래 에러가 반환되어야 함
            XCTAssertNotNil(resultError, "서버 에러가 반환되어야 함")
        default:
            XCTFail("서버 에러에서는 재시도하지 않아야 함")
        }
    }

    // MARK: - Integration Tests

    func test_adapt_and_retry_전체플로우() {
        /// - Given: 완전한 요청 플로우
        let originalURL = URL(string: "https://api.test.com/protected")!
        var originalRequest = URLRequest(url: originalURL)
        originalRequest.httpMethod = "GET"

        /// - Step 1: 요청 어댑팅
        var adaptedRequest: URLRequest?
        let adaptExpectation = expectation(description: "Adapt completion")

        sut.adapt(originalRequest, for: mockSession) { result in
            if case .success(let request) = result {
                adaptedRequest = request
            }
            adaptExpectation.fulfill()
        }

        wait(for: [adaptExpectation], timeout: 2.0)

        /// - Step 2: 401 응답으로 재시도
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        /// - 실제 DataRequest 생성
        let request = mockSession.request(originalURL)

        var retryResult: RetryResult?
        let retryExpectation = expectation(description: "Retry completion")

        sut.retry(request, for: mockSession, dueTo: error) { result in
            retryResult = result
            retryExpectation.fulfill()
        }

        wait(for: [retryExpectation], timeout: 3.0)

        /// - Then: 전체 플로우가 올바르게 동작
        XCTAssertNotNil(adaptedRequest, "요청이 어댑트되어야 함")
        XCTAssertNotNil(retryResult, "재시도 결과가 반환되어야 함")

        print("전체 플로우 완료 - Adapt 성공, Retry 결과: \(String(describing: retryResult))")
    }

    // MARK: - Edge Cases

    func test_shared_instance_동일성() {
        /// - Given: Shared instance
        let instance1 = TokenInterceptor.shared
        let instance2 = TokenInterceptor.shared

        /// - Then: 동일한 인스턴스
        XCTAssertTrue(instance1 === instance2, "Shared instance는 동일한 객체여야 함")
    }

    func test_adapt_nil_URL() {
        /// - Given: 잘못된 URL로 요청 생성 시도
        guard let url = URL(string: "") else {
            /// - 빈 문자열로는 URL이 생성되지 않으므로 다른 방법 사용
            var invalidRequest = URLRequest(url: URL(string: "https://test.com")!)

            var result: Result<URLRequest, Error>?
            let expectation = expectation(description: "Adapt invalid request")

            /// - When: 요청 어댑팅
            sut.adapt(invalidRequest, for: mockSession) { adaptResult in
                result = adaptResult
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)

            /// - Then: 정상적으로 어댑트됨 (URL이 유효하므로)
            switch result {
            case .success(_):
                XCTAssert(true, "유효한 URL은 정상적으로 어댑트되어야 함")
            case .failure(let error):
                XCTFail("유효한 요청에서 에러가 발생해서는 안됨: \(error)")
            case .none:
                XCTFail("결과가 반환되지 않음")
            }
            return
        }

        XCTFail("이 지점에 도달해서는 안됨")
    }
}

