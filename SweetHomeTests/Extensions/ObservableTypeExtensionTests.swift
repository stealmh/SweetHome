///// - ObservableTypeExtensionTests: RxSwift ObservableType Extension 테스트
///// - catchSHError(), logError() 메서드의 에러 처리 기능 검증
//
//import XCTest
//import RxSwift
//import RxTest
//@testable import SweetHome
//
//final class ObservableTypeExtensionTests: BaseTestCase {
//
//    // MARK: - catchSHError Tests
//
//    func test_catchSHError_일반_에러를_SHError로_변환() {
//        /// - Given: 일반 NSError 발생하는 Observable
//        let normalError = NSError(domain: "TestDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Test error"])
//        let errorObservable = Observable<String>.error(normalError)
//
//        /// - When: catchSHError 적용
//        let resultObservable = errorObservable.catchSHError()
//
//        /// - Then: SHError로 변환되어 방출되는지 확인
//        var receivedError: Error?
//        let errorExpectation = expectation(description: "Error received")
//
//        _ = resultObservable
//            .subscribe(onError: { error in
//                receivedError = error
//                errorExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertNotNil(receivedError)
//        XCTAssertTrue(receivedError is SHError, "에러가 SHError로 변환되어야 함")
//
//        /// - SHError의 내용 확인
//        if let shError = receivedError as? SHError {
//            switch shError {
//            case .networkError(_):
//                // NSError는 일반적으로 networkError로 변환됨
//                break
//            default:
//                XCTFail("NSError는 적절한 SHError 타입으로 변환되어야 함")
//            }
//        }
//    }
//
//    func test_catchSHError_이미_SHError인_경우() {
//        /// - Given: 이미 SHError인 Observable
//        let originalSHError = SHError.networkError(.decodingError)
//        let errorObservable = Observable<String>.error(originalSHError)
//
//        /// - When: catchSHError 적용
//        let resultObservable = errorObservable.catchSHError()
//
//        /// - Then: 동일한 SHError가 방출되는지 확인
//        var receivedError: SHError?
//        let errorExpectation = expectation(description: "SHError received")
//
//        _ = resultObservable
//            .subscribe(onError: { error in
//                receivedError = error as? SHError
//                errorExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertNotNil(receivedError)
//        XCTAssertEqual(receivedError, originalSHError, "원래 SHError와 동일해야 함")
//    }
//
//    func test_catchSHError_정상_값은_통과() {
//        /// - Given: 정상 값을 방출하는 Observable
//        let normalObservable = Observable.just("정상 데이터")
//
//        /// - When: catchSHError 적용
//        let resultObservable = normalObservable.catchSHError()
//
//        /// - Then: 정상 값이 그대로 방출되는지 확인
//        var receivedValue: String?
//        let valueExpectation = expectation(description: "Value received")
//
//        _ = resultObservable
//            .subscribe(onNext: { value in
//                receivedValue = value
//                valueExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertEqual(receivedValue, "정상 데이터", "정상 값은 그대로 통과해야 함")
//    }
//
//    func test_catchSHError_여러_값과_에러_시퀀스() {
//        /// - Given: 값들과 에러가 순차적으로 발생하는 Observable
//        let testScheduler = TestScheduler(initialClock: 0)
//        let errorToThrow = NSError(domain: "TestDomain", code: 500, userInfo: nil)
//
//        let sourceObservable = testScheduler.createHotObservable([
//            .next(10, "첫 번째"),
//            .next(20, "두 번째"),
//            .error(30, errorToThrow)
//        ])
//
//        /// - When: catchSHError 적용
//        let resultObservable = sourceObservable.asObservable().catchSHError()
//
//        /// - Then: 값들과 SHError 방출 확인
//        let observer = testScheduler.createObserver(String.self)
//        resultObservable.subscribe(observer).disposed(by: disposeBag)
//
//        testScheduler.start()
//
//        /// - 정상 값들은 그대로 방출
//        XCTAssertEqual(observer.events.count, 3) // next(10), next(20), error(30)
//        XCTAssertEqual(observer.events[0].value.element, "첫 번째")
//        XCTAssertEqual(observer.events[1].value.element, "두 번째")
//
//        /// - 에러는 SHError로 변환
//        if case .error(let error) = observer.events[2].value {
//            XCTAssertTrue(error is SHError, "에러가 SHError로 변환되어야 함")
//        } else {
//            XCTFail("세 번째 이벤트는 에러여야 함")
//        }
//    }
//
//    // MARK: - logError Tests
//
//    func test_logError_에러_로깅_후_계속_진행() {
//        /// - Given: 에러가 발생하는 Observable
//        let testError = NSError(domain: "LogTestDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Log test error"])
//        let errorObservable = Observable<Int>.error(testError)
//
//        /// - When: logError 적용
//        let resultObservable = errorObservable.logError()
//
//        /// - Then: 에러가 로깅되고 그대로 방출되는지 확인
//        var loggedError: Error?
//        var finalError: Error?
//
//        let errorExpectation = expectation(description: "Error logged and propagated")
//
//        _ = resultObservable
//            .do(onError: { error in
//                loggedError = error
//            })
//            .subscribe(onError: { error in
//                finalError = error
//                errorExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        /// - 에러가 로깅되고 계속 전파되었는지 확인
//        XCTAssertNotNil(finalError, "에러가 최종적으로 방출되어야 함")
//        XCTAssertEqual((finalError as? NSError)?.domain, testError.domain, "원래 에러가 보존되어야 함")
//    }
//
//    func test_logError_정상_값은_영향_없음() {
//        /// - Given: 정상 값들을 방출하는 Observable
//        let normalObservable = Observable.from([1, 2, 3, 4, 5])
//
//        /// - When: logError 적용
//        let resultObservable = normalObservable.logError()
//
//        /// - Then: 정상 값들이 그대로 방출되는지 확인
//        let results = waitForCompletion(resultObservable)
//
//        XCTAssertEqual(results, [1, 2, 3, 4, 5], "정상 값들은 영향받지 않아야 함")
//    }
//
//    func test_logError_SHError_로깅() {
//        /// - Given: SHError가 발생하는 Observable
//        let shError = SHError.commonError(.weakSelfFailure)
//        let errorObservable = Observable<String>.error(shError)
//
//        /// - When: logError 적용
//        let resultObservable = errorObservable.logError()
//
//        /// - Then: SHError가 로깅되고 전파되는지 확인
//        var receivedError: SHError?
//        let errorExpectation = expectation(description: "SHError logged")
//
//        _ = resultObservable
//            .subscribe(onError: { error in
//                receivedError = error as? SHError
//                errorExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertNotNil(receivedError)
//        XCTAssertEqual(receivedError, shError, "원래 SHError가 보존되어야 함")
//    }
//
//    // MARK: - Integration Tests
//
//    func test_catchSHError_와_logError_함께_사용() {
//        /// - Given: 일반 에러가 발생하는 Observable
//        let normalError = URLError(.badURL)
//        let errorObservable = Observable<Data>.error(normalError)
//
//        /// - When: logError 먼저 적용 후 catchSHError 적용
//        let resultObservable = errorObservable
//            .logError()
//            .catchSHError()
//
//        /// - Then: 로깅 후 SHError로 변환되는지 확인
//        var finalError: SHError?
//        let errorExpectation = expectation(description: "Error logged and converted")
//
//        _ = resultObservable
//            .subscribe(onError: { error in
//                finalError = error as? SHError
//                errorExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertNotNil(finalError)
//        XCTAssertTrue(finalError is SHError, "최종적으로 SHError가 되어야 함")
//
//        /// - URLError는 일반적으로 networkError로 변환됨
//        if case .networkError(_) = finalError {
//            // 성공
//        } else {
//            XCTFail("URLError는 networkError로 변환되어야 함")
//        }
//    }
//
//    func test_실제_네트워크_시나리오_시뮬레이션() {
//        /// - Given: 네트워크 요청을 시뮬레이션하는 Observable
//        let testScheduler = TestScheduler(initialClock: 0)
//
//        let networkObservable = testScheduler.createHotObservable([
//            .next(10, "데이터 로딩 시작"),
//            .next(50, "일부 데이터 수신"),
//            .error(100, URLError(.timedOut)) // 타임아웃 에러
//        ])
//
//        /// - When: 실제 앱에서 사용하는 것처럼 에러 처리 체인 적용
//        let processedObservable = networkObservable.asObservable()
//            .logError() // 에러 로깅
//            .catchSHError() // SHError로 변환
//
//        /// - Then: 결과 확인
//        let observer = testScheduler.createObserver(String.self)
//        processedObservable.subscribe(observer).disposed(by: disposeBag)
//
//        testScheduler.start()
//
//        /// - 정상 데이터는 통과
//        XCTAssertEqual(observer.events[0].value.element, "데이터 로딩 시작")
//        XCTAssertEqual(observer.events[1].value.element, "일부 데이터 수신")
//
//        /// - 에러는 SHError로 변환되어 방출
//        if case .error(let error) = observer.events[2].value {
//            XCTAssertTrue(error is SHError, "URLError가 SHError로 변환되어야 함")
//
//            if let shError = error as? SHError,
//               case .networkError(let networkError) = shError {
//                print("✅ 네트워크 에러가 SHError로 성공적으로 변환됨: \(networkError)")
//            }
//        } else {
//            XCTFail("타임아웃 에러가 SHError로 변환되어 방출되어야 함")
//        }
//    }
//
//    // MARK: - Edge Cases
//
//    func test_빈_Observable에_extension_적용() {
//        /// - Given: 빈 Observable
//        let emptyObservable = Observable<String>.empty()
//
//        /// - When: extension들 적용
//        let resultObservable = emptyObservable
//            .logError()
//            .catchSHError()
//
//        /// - Then: 정상적으로 완료되는지 확인
//        var completed = false
//        let completionExpectation = expectation(description: "Empty observable completed")
//
//        _ = resultObservable
//            .subscribe(onCompleted: {
//                completed = true
//                completionExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//
//        waitForExpectations(timeout: 1.0)
//
//        XCTAssertTrue(completed, "빈 Observable도 정상적으로 완료되어야 함")
//    }
//
//    func test_never_Observable에_extension_적용() {
//        /// - Given: 무한히 대기하는 Observable
//        let neverObservable = Observable<Int>.never()
//
//        /// - When: extension들 적용
//        let resultObservable = neverObservable
//            .logError()
//            .catchSHError()
//
//        /// - Then: 에러 없이 적용되는지 확인
//        XCTAssertNoThrow(
//            _ = resultObservable.subscribe().disposed(by: disposeBag),
//            "Never Observable에도 extension이 안전하게 적용되어야 함"
//        )
//    }
//
//    // MARK: - Performance Tests
//
//    func test_extension_성능_테스트() {
//        /// - Given: 많은 데이터를 처리하는 Observable
//        let largeDataObservable = Observable.from(1...10000)
//
//        measure {
//            /// - When: extension들을 적용하여 처리
//            _ = largeDataObservable
//                .logError()
//                .catchSHError()
//                .toBlocking()
//                .materialize()
//        }
//    }
//}
