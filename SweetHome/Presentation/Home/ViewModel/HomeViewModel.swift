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
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let todayEstates: Driver<[Estate]>
        let error: Driver<SHError>
        let autoScrollTrigger: Driver<Void>
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
        let errorRelay = PublishSubject<SHError>()
        
        input.onAppear
            .do(onNext: { _ in
                isLoadingRelay.onNext(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<BaseEstateResponse> in
                guard let self else { return Observable.error(SHError.commonError(.weakSelfFailure)) }
                return self.apiClient.requestObservable(EstateEndpoint.todayEstates)
                    .catch { error -> Observable<BaseEstateResponse> in
                        errorRelay.onNext(SHError.from(error))
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { response in
                isLoadingRelay.onNext(false)
                let estates = response.data.map { $0.toDomain }
                todayEstatesRelay.onNext(estates)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        // 타이머 시작 로직
        input.startAutoScroll
            .subscribe(onNext: { [weak self] _ in
                self?.startAutoScroll()
            })
            .disposed(by: disposeBag)
        
        // 타이머 정지 로직
        input.stopAutoScroll
            .subscribe(onNext: { [weak self] _ in
                self?.stopAutoScroll()
            })
            .disposed(by: disposeBag)
        
        // 사용자 스크롤 상태에 따른 타이머 제어
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
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            todayEstates: todayEstatesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            autoScrollTrigger: autoScrollTriggerRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    // MARK: - Auto Scroll Methods
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