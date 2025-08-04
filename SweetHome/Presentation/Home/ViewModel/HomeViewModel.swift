//
//  HomeViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/3/25.
//

import Foundation
import RxSwift
import RxCocoa

class HomeViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let onAppear: Observable<Void>
        let startAutoScroll: Observable<Void>
        let stopAutoScroll: Observable<Void>
        let userScrolling: Observable<Bool>
        let viewAllTapped: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let todayEstates: Driver<[Estate]>
        let error: Driver<SHError>
        let autoScrollTrigger: Driver<Void>
        let recentSearchEstates: Driver<[DetailEstate]>
        let hotEstates: Driver<[Estate]>
        let topics: Driver<[EstateTopic]>
    }
    
    private let apiClient: ApiClient
    private var autoScrollTimer: Timer?
    private let autoScrollTriggerRelay = PublishSubject<Void>()
    
    init(apiClient: ApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let todayEstatesRelay = BehaviorSubject<[Estate]>(value: [])
        let hotEstatesRelay = BehaviorSubject<[Estate]>(value: [])
        let topicsRelay = BehaviorSubject<[EstateTopic]>(value: [])
        let errorRelay = PublishSubject<SHError>()
        
        let _ = input.onAppear
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self else { return Observable.error(SHError.commonError(.weakSelfFailure)) }
                
                let todayEstatesObservable = self.apiClient
                    .requestObservable(EstateEndpoint.todayEstates)
                    .map { (response: BaseEstateResponse) -> [Estate] in
                        response.data.map { $0.toDomain }
                    }
                    .catch { error -> Observable<[Estate]> in
                        errorRelay.onNext(SHError.from(error))
                        return Observable.just([])
                    }
                
                let hotEstatesObservable = self.apiClient
                    .requestObservable(EstateEndpoint.hotEstates)
                    .map { (response: BaseEstateResponse) -> [Estate] in
                        response.data.map { $0.toDomain }
                    }
                    .catch { error -> Observable<[Estate]> in
                        errorRelay.onNext(SHError.from(error))
                        return Observable.just([])
                    }
                
                let topicsObservable = self.apiClient
                    .requestObservable(EstateEndpoint.topics)
                    .map { (response: EstateTopicResponse) -> [EstateTopic] in
                        response.data.map { $0.toDomain }
                    }
                    .catch { error -> Observable<[EstateTopic]> in
                        errorRelay.onNext(SHError.from(error))
                        return Observable.just([])
                    }
                
                return Observable.combineLatest(
                    todayEstatesObservable,
                    hotEstatesObservable,
                    topicsObservable
                ) { todayEstates, hotEstates, topics in
                    
                    todayEstatesRelay.onNext(todayEstates)
                    hotEstatesRelay.onNext(hotEstates)
                    topicsRelay.onNext(topics)
                    isLoadingRelay.onNext(false)
                    return ()
                }
            }
            .subscribe(onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        input.startAutoScroll
            .subscribe(onNext: { [weak self] _ in
                self?.startAutoScroll()
            })
            .disposed(by: disposeBag)
        
        input.stopAutoScroll
            .subscribe(onNext: { [weak self] _ in
                self?.stopAutoScroll()
            })
            .disposed(by: disposeBag)
        
        input.userScrolling
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isScrolling in
                if isScrolling {
                    self?.stopAutoScroll()
                } else {
                    self?.startAutoScroll()
                }
            })
            .disposed(by: disposeBag)
        
        let recentSearchEstates = input.onAppear
            .map { _ in DetailEstate.mockData }
            .asDriver(onErrorJustReturn: [])
        
        input.viewAllTapped
            .subscribe(onNext: { _ in
                print("👀 View All 버튼 탭됨 - 최근 검색 매물")
            })
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            todayEstates: todayEstatesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            autoScrollTrigger: autoScrollTriggerRelay.asDriver(onErrorDriveWith: .empty()),
            recentSearchEstates: recentSearchEstates,
            hotEstates: hotEstatesRelay.asDriver(onErrorDriveWith: .empty()),
            topics: topicsRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.autoScrollTriggerRelay.onNext(())
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    deinit {
        stopAutoScroll()
    }
}
