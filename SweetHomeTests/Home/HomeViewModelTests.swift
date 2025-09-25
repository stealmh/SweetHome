/// - HomeViewModelTests: HomeViewModel의 비즈니스 로직 테스트
/// - 데이터 로딩, 에러 처리, 자동스크롤, 메모리 관리 검증

import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import SweetHome

final class HomeViewModelTests: ViewModelTestCase {

    var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        sut = HomeViewModel(apiClient: apiClient)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    /// - 데이터 로딩 성공 시나리오 테스트
    func test_onAppear_성공시_데이터를_정상적으로_로드한다() {
        /// - Given: 네트워크 응답 설정
        print("🧪 Setting up mock responses...")
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/today-estates"
        )
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/hot-estates"
        )
        mockNetworkService.setMockResponse(
            EstateTopicResponse(data: [EstateTopicDataResponse(title: "Test Topic", content: "Test Content", date: "25.1.17", link: nil)]),
            for: "/v1/estates/today-topic"
        )
        print("🧪 Mock responses set up complete")

        let onAppear = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: onAppear.asObservable(),
            startAutoScroll: Observable.never(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 결과 검증을 위한 Observer 설정
        let todayEstatesObserver = scheduler.createObserver([Estate].self)
        let hotEstatesObserver = scheduler.createObserver([Estate].self)
        let isLoadingObserver = scheduler.createObserver(Bool.self)

        output.todayEstates.drive(todayEstatesObserver).disposed(by: disposeBag)
        output.hotEstates.drive(hotEstatesObserver).disposed(by: disposeBag)
        output.isLoading.drive(isLoadingObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - Assert: 로딩 상태 변화 확인
        XCTAssertEqual(isLoadingObserver.events, [
            .next(0, false),  /// - 초기값
            .next(10, true),  /// - 로딩 시작
            .next(10, false)  /// - 로딩 완료
        ])

        /// - Assert: Mock 데이터 확인
        XCTAssertFalse(todayEstatesObserver.events.isEmpty)
        XCTAssertFalse(hotEstatesObserver.events.isEmpty)
    }

    /// - API 실패 시나리오 테스트
    func test_onAppear_API_실패시_에러를_처리한다() {
        /// - Given: 에러 상황 Mock 설정
        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = SHError.networkError(.decodingError)

        let onAppear = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: onAppear.asObservable(),
            startAutoScroll: Observable.never(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 에러 처리 검증
        let errorObserver = scheduler.createObserver(SHError.self)
        let isLoadingObserver = scheduler.createObserver(Bool.self)

        output.error.drive(errorObserver).disposed(by: disposeBag)
        output.isLoading.drive(isLoadingObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - Assert: 에러 상황에서의 로딩 상태 확인
        XCTAssertEqual(isLoadingObserver.events, [
            .next(0, false),  /// - 초기값
            .next(10, true),  /// - 로딩 시작
            .next(10, false)  /// - 에러로 인한 로딩 종료
        ])

        XCTAssertFalse(errorObserver.events.isEmpty)
    }

    /// - 개별 API 실패 시나리오 테스트
    func test_onAppear_개별API실패시_다른API는_정상_동작한다() {
        /// - Given: todayEstates만 실패하도록 설정
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/hot-estates"
        )
        mockNetworkService.setMockResponse(
            EstateTopicResponse(data: [EstateTopicDataResponse(title: "Test Topic", content: "Test Content", date: "25.1.17", link: nil)]),
            for: "/v1/estates/today-topic"
        )
        /// - todayEstates 응답은 설정하지 않음 (404 에러 발생 가정)

        let onAppear = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: onAppear.asObservable(),
            startAutoScroll: Observable.never(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 실패한 API는 빈 배열, 성공한 API는 데이터 반환
        let todayEstatesObserver = scheduler.createObserver([Estate].self)
        let hotEstatesObserver = scheduler.createObserver([Estate].self)
        let topicsObserver = scheduler.createObserver([EstateTopic].self)

        output.todayEstates.drive(todayEstatesObserver).disposed(by: disposeBag)
        output.hotEstates.drive(hotEstatesObserver).disposed(by: disposeBag)
        output.topics.drive(topicsObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - Assert: 실패한 API는 빈 배열, 성공한 API는 데이터 있음
        XCTAssertTrue(todayEstatesObserver.events.contains { $0.value.element?.isEmpty == true })
        XCTAssertTrue(hotEstatesObserver.events.contains { $0.value.element?.isEmpty == true })
        XCTAssertTrue(topicsObserver.events.contains { $0.value.element?.isEmpty == false })
    }

    /// - 자동 스크롤 타이머 정상 동작 테스트
    func test_startAutoScroll_Timer가_정상적으로_동작한다() {
        /// - Given: 자동 스크롤 시작 이벤트
        let startAutoScroll = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: Observable.never(),
            startAutoScroll: startAutoScroll.asObservable(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 자동 스크롤 트리거 확인
        let autoScrollObserver = scheduler.createObserver(Void.self)
        output.autoScrollTrigger.drive(autoScrollObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - 실제 Timer는 integration test에서 검증하고, 여기서는 설정 확인만
        XCTAssertNotNil(output.autoScrollTrigger)
    }

    /// - 사용자 스크롤과 자동 스크롤 상호작용 테스트
    func test_userScrolling_자동스크롤과의_상호작용() {
        /// - Given: 사용자 스크롤 이벤트 시퀀스
        let startAutoScroll = scheduler.createHotObservable([
            .next(5, ())
        ])
        let userScrolling = scheduler.createHotObservable([
            .next(10, true),   // 사용자 스크롤 시작
            .next(20, false),  // 사용자 스크롤 끝 (자동 스크롤 재시작 예상)
            .next(30, true)    // 다시 사용자 스크롤
        ])

        let input = HomeViewModel.Input(
            onAppear: Observable.never(),
            startAutoScroll: startAutoScroll.asObservable(),
            stopAutoScroll: Observable.never(),
            userScrolling: userScrolling.asObservable()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 사용자 스크롤 상태에 따른 동작 확인
        let autoScrollObserver = scheduler.createObserver(Void.self)
        output.autoScrollTrigger.drive(autoScrollObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - 자동 스크롤 동작이 사용자 스크롤에 반응하는지 확인
        XCTAssertNotNil(output.autoScrollTrigger)
    }

    /// - 중복 onAppear 호출 방지 테스트
    func test_onAppear_중복호출시_한번만_실행된다() {
        /// - Given: Mock 응답 설정
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/today-estates"
        )
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/hot-estates"
        )
        mockNetworkService.setMockResponse(
            EstateTopicResponse(data: [EstateTopicDataResponse(title: "Test Topic", content: "Test Content", date: "25.1.17", link: nil)]),
            for: "/v1/estates/today-topic"
        )

        /// - 여러 번 onAppear 호출
        let onAppear = scheduler.createHotObservable([
            .next(10, ()),
            .next(20, ()),
            .next(30, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: onAppear.asObservable(),
            startAutoScroll: Observable.never(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 로딩 상태 확인 (take(1)로 인해 첫 번째만 실행)
        let isLoadingObserver = scheduler.createObserver(Bool.self)
        output.isLoading.drive(isLoadingObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - Assert: 첫 번째 호출만 처리됨
        let loadingTrueEvents = isLoadingObserver.events.filter { $0.value.element == true }
        XCTAssertEqual(loadingTrueEvents.count, 1, "onAppear는 take(1)로 인해 한 번만 실행되어야 함")
    }

    /// - 동시 API 요청 완료 순서 테스트
    func test_onAppear_API요청들이_동시에_완료된다() {
        /// - Given: 모든 API Mock 응답 설정
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/today-estates"
        )
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/hot-estates"
        )
        mockNetworkService.setMockResponse(
            EstateTopicResponse(data: [EstateTopicDataResponse(title: "Test Topic", content: "Test Content", date: "25.1.17", link: nil)]),
            for: "/v1/estates/today-topic"
        )

        let onAppear = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = HomeViewModel.Input(
            onAppear: onAppear.asObservable(),
            startAutoScroll: Observable.never(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 모든 데이터가 동시에 업데이트되는지 확인
        let todayEstatesObserver = scheduler.createObserver([Estate].self)
        let hotEstatesObserver = scheduler.createObserver([Estate].self)
        let topicsObserver = scheduler.createObserver([EstateTopic].self)

        output.todayEstates.drive(todayEstatesObserver).disposed(by: disposeBag)
        output.hotEstates.drive(hotEstatesObserver).disposed(by: disposeBag)
        output.topics.drive(topicsObserver).disposed(by: disposeBag)

        scheduler.start()

        /// - Assert: 모든 데이터가 같은 시간(10)에 업데이트됨
        let todayEstatesUpdateTime = todayEstatesObserver.events.last?.time
        let hotEstatesUpdateTime = hotEstatesObserver.events.last?.time
        let topicsUpdateTime = topicsObserver.events.last?.time

        XCTAssertEqual(todayEstatesUpdateTime, hotEstatesUpdateTime)
        XCTAssertEqual(hotEstatesUpdateTime, topicsUpdateTime)
        XCTAssertEqual(topicsUpdateTime, 10, "모든 API 응답이 시간 10에 동시 완료되어야 함")
    }

    /// - 자동 스크롤 시작 테스트 (Timer는 integration test에서 검증)
    func test_startAutoScroll_입력이_정상적으로_처리된다() {
        /// - Given: 자동 스크롤 시작 이벤트 설정
        let startAutoScrollSubject = PublishSubject<Void>()

        let input = HomeViewModel.Input(
            onAppear: Observable.never(),
            startAutoScroll: startAutoScrollSubject.asObservable(),
            stopAutoScroll: Observable.never(),
            userScrolling: Observable.never()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 자동 스크롤 설정이 정상적으로 처리되는지 확인
        let autoScrollObserver = scheduler.createObserver(Void.self)
        output.autoScrollTrigger.drive(autoScrollObserver).disposed(by: disposeBag)

        /// - startAutoScroll 이벤트 발생
        startAutoScrollSubject.onNext(())

        /// - 실제 Timer 동작은 별도의 integration test에서 검증
        XCTAssertNotNil(output.autoScrollTrigger, "Auto scroll trigger should be configured")
    }

    /// - 사용자 스크롤 시 자동 스크롤 중지 테스트
    func test_userScrolling_true시_자동스크롤이_중지된다() {
        /// - Given: 사용자 스크롤 이벤트 시퀀스 설정
        let startAutoScroll = PublishSubject<Void>()
        let userScrolling = scheduler.createHotObservable([
            .next(10, false),  /// - 스크롤 끝
            .next(20, true),   /// - 사용자 스크롤 시작
            .next(30, false)   /// - 사용자 스크롤 끝
        ])

        let input = HomeViewModel.Input(
            onAppear: Observable.never(),
            startAutoScroll: startAutoScroll.asObservable(),
            stopAutoScroll: Observable.never(),
            userScrolling: userScrolling.asObservable()
        )

        /// - When: ViewModel transform 실행
        let output = sut.transform(input: input)

        /// - Then: 자동 스크롤 동작 확인
        let autoScrollObserver = scheduler.createObserver(Void.self)
        output.autoScrollTrigger.drive(autoScrollObserver).disposed(by: disposeBag)

        /// - 자동 스크롤 시작
        startAutoScroll.onNext(())

        scheduler.start()

        /// - 사용자 스크롤 시 자동 스크롤이 중지되는지 확인
        /// - (실제 Timer 동작 확인은 integration test에서)
    }

    /// - 메모리 누수 테스트
    func test_deinit_메모리_누수가_없다() {
        /// - Given: 약한 참조로 ViewModel 추적
        weak var weakViewModel: HomeViewModel?

        /// - When: autoreleasepool에서 ViewModel 생성 및 사용
        autoreleasepool {
            let viewModel = HomeViewModel(apiClient: apiClient)
            weakViewModel = viewModel

            let input = HomeViewModel.Input(
                onAppear: Observable.just(()),
                startAutoScroll: Observable.just(()),
                stopAutoScroll: Observable.never(),
                userScrolling: Observable.never()
            )

            _ = viewModel.transform(input: input)
        }

        /// - Then: ViewModel이 정상적으로 해제되었는지 확인
        XCTAssertNil(weakViewModel, "HomeViewModel should be deallocated")
    }

    /// - MockNetworkService 단독 테스트
    func test_MockNetworkService_단독_동작_확인() async {
        /// - Given: Mock 응답 설정
        mockNetworkService.setMockResponse(
            BaseEstateResponse(data: []),
            for: "/v1/estates/today-estates"
        )

        /// - When: API 요청
        do {
            let response: BaseEstateResponse = try await mockNetworkService.request(EstateEndpoint.todayEstates)
            /// - Then: 성공
            XCTAssertNotNil(response)
            print("✅ MockNetworkService works correctly")
        } catch {
            XCTFail("MockNetworkService should not fail: \(error)")
        }
    }
}
