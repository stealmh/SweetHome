/// - MockNetworkService: 테스트용 NetworkService Mock 구현체
/// - 실제 네트워크 호출 없이 API 응답을 시뮬레이션
/// - 성공/실패 시나리오, 지연 시간, 호출 횟수 추적 기능 제공

import Foundation
import RxSwift
@testable import SweetHome

final class MockNetworkService {

    /// - 테스트 설정: 에러 반환 여부
    var shouldReturnError = false
    /// - 반환할 에러 객체
    var errorToReturn: Error = SHError.networkError(.decodingError)
    /// - 네트워크 지연 시뮬레이션 시간
    var delayTime: TimeInterval = 0

    /// - Mock 응답 데이터 저장소 (Thread-safe)
    private let mockResponsesQueue = DispatchQueue(label: "mock.responses.queue", attributes: .concurrent)
    private var _mockResponses: [String: Any] = [:]
    /// - API 호출 횟수 추적 (Thread-safe)
    private let callCountsQueue = DispatchQueue(label: "mock.callcounts.queue", attributes: .concurrent)
    private var _callCounts: [String: Int] = [:]

    /// - 특정 엔드포인트의 호출 횟수 반환
    func getCallCount(for endpointPath: String) -> Int {
        return callCountsQueue.sync {
            return _callCounts[endpointPath, default: 0]
        }
    }

    /// - Mock 응답 데이터 설정
    func setMockResponse<T>(_ response: T, for endpointPath: String) {
        mockResponsesQueue.sync(flags: .barrier) {
            _mockResponses[endpointPath] = response
        }
    }

    /// - 호출 횟수 초기화
    func resetCallCounts() {
        callCountsQueue.sync(flags: .barrier) {
            _callCounts.removeAll()
        }
    }

    /// - 모든 Mock 설정 초기화
    func resetMocks() {
        mockResponsesQueue.sync(flags: .barrier) {
            _mockResponses.removeAll()
        }
        callCountsQueue.sync(flags: .barrier) {
            _callCounts.removeAll()
        }
        shouldReturnError = false
        delayTime = 0
    }
}

extension MockNetworkService: NetworkServiceProtocol {
    /// - 일반 API 요청 Mock 구현 (TestScheduler 호환을 위한 동기식)
    func request<T: Decodable>(_ target: TargetType) async throws -> T {
        let endpointPath = target.path

        /// - 호출 횟수 업데이트 (동기식으로 변경)
        callCountsQueue.sync(flags: .barrier) {
            _callCounts[endpointPath] = (_callCounts[endpointPath] ?? 0) + 1
        }

        /// - 에러 시나리오 시뮬레이션
        if shouldReturnError {
            throw errorToReturn
        }

        /// - 설정된 Mock 응답 반환 (동기식)
        let mockResponse = mockResponsesQueue.sync {
            return _mockResponses[endpointPath]
        }

        guard let typedResponse = mockResponse as? T else {
            let errorMessage = "Mock response not found for \(endpointPath). Expected type: \(T.self). Available: \(_mockResponses.keys.sorted())"
            throw SHError.networkError(.unknown(statusCode: 404, message: errorMessage))
        }

        return typedResponse
    }

    /// - 파일 업로드 API Mock 구현
    func upload(_ target: TargetType) async throws -> ChatUploadResponse {
        let endpointPath = target.path

        /// - 호출 횟수 업데이트 (Thread-safe)
        callCountsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self._callCounts[endpointPath] = (self._callCounts[endpointPath] ?? 0) + 1
        }

        /// - 네트워크 지연 시뮬레이션
        if delayTime > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
        }

        /// - 에러 시나리오 시뮬레이션
        if shouldReturnError {
            throw errorToReturn
        }

        /// - 설정된 Mock 응답 반환 (Thread-safe)
        let mockResponse = mockResponsesQueue.sync {
            return _mockResponses[endpointPath]
        }

        guard let typedResponse = mockResponse as? ChatUploadResponse else {
            throw SHError.networkError(.unknown(statusCode: 404, message: "Mock upload response not found for \(endpointPath). Expected type: ChatUploadResponse"))
        }

        return typedResponse
    }
}
