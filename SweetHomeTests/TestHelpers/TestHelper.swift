/// - TestHelper: 테스트용 유틸리티 클래스들 모음
/// - BaseTestCase: RxSwift 테스트를 위한 기본 클래스
/// - ViewModelTestCase: ViewModel 테스트를 위한 전용 클래스

import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SweetHome

/// - 모든 테스트의 기본이 되는 베이스 클래스
/// - RxSwift 테스트에 필요한 DisposeBag, TestScheduler 제공
class BaseTestCase: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }

    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        super.tearDown()
    }
}

/// - ViewModel 테스트 전용 클래스
/// - MockNetworkService와 TestApiClient가 사전 구성됨
class ViewModelTestCase: BaseTestCase {
    var mockNetworkService: MockNetworkService!
    var apiClient: ApiClientProtocol!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        apiClient = TestApiClient(network: mockNetworkService, scheduler: scheduler)
    }

    override func tearDown() {
        apiClient = nil
        mockNetworkService = nil
        super.tearDown()
    }
}

class TestApiClient: ApiClientProtocol {
    private let network: NetworkServiceProtocol
    private let scheduler: TestScheduler

    init(network: NetworkServiceProtocol, scheduler: TestScheduler) {
        self.network = network
        self.scheduler = scheduler
    }

    func requestObservable<T: Decodable>(_ endpoint: TargetType) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SHError.networkError(.unknown(statusCode: nil, message: "TestApiClient가 해제되었습니다.")))
                return Disposables.create()
            }

            do {
                var result: Result<T, Error>?
                let semaphore = DispatchSemaphore(value: 0)

                Task {
                    do {
                        let response: T = try await self.network.request(endpoint)
                        result = .success(response)
                    } catch {
                        result = .failure(error)
                    }
                    semaphore.signal()
                }

                semaphore.wait()

                switch result {
                case .success(let response):
                    observer.onNext(response)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                case .none:
                    observer.onError(SHError.networkError(.unknown(statusCode: nil, message: "Request failed")))
                }

            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func uploadObservable(_ endpoint: TargetType) -> Observable<ChatUploadResponse> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(SHError.networkError(.unknown(statusCode: nil, message: "TestApiClient가 해제되었습니다.")))
                return Disposables.create()
            }

            do {
                var result: Result<ChatUploadResponse, Error>?
                let semaphore = DispatchSemaphore(value: 0)

                Task {
                    do {
                        let response: ChatUploadResponse = try await self.network.upload(endpoint)
                        result = .success(response)
                    } catch {
                        result = .failure(error)
                    }
                    semaphore.signal()
                }

                semaphore.wait()

                switch result {
                case .success(let response):
                    observer.onNext(response)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                case .none:
                    observer.onError(SHError.networkError(.unknown(statusCode: nil, message: "Upload failed")))
                }

            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}
// MARK: - XCTestCase Extensions
extension XCTestCase {

    /// - Observable 완료를 기다리고 결과를 반환하는 헬퍼 함수
    func waitForCompletion<T>(
        _ observable: Observable<T>,
        timeout: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [T] {
        var results: [T] = []
        let expectation = expectation(description: "Observable completion")
        let disposeBag = DisposeBag()

        observable
            .subscribe(
                onNext: { value in
                    results.append(value)
                },
                onCompleted: {
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: timeout)
        return results
    }

    /// - Observable에서 에러 발생을 기대하는 헬퍼 함수
    func expectError<T>(
        from observable: Observable<T>,
        timeout: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        var receivedError: Error?
        let expectation = expectation(description: "Error expectation")
        let disposeBag = DisposeBag()

        observable
            .subscribe(
                onError: { error in
                    receivedError = error
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: timeout)
        return receivedError
    }

    /// - 에러 시나리오용 Mock ApiClient 생성 헬퍼
    func createMockApiClient(shouldReturnError: Bool = false) -> ApiClient {
        let mockNetwork = MockNetworkService()
        mockNetwork.shouldReturnError = shouldReturnError
        return ApiClient(network: mockNetwork)
    }
}

