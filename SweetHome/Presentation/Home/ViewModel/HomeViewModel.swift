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
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let todayEstates: Driver<[Estate]>
        let error: Driver<SHError>
    }
    
    private let apiClient: ApiClient
    
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
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            todayEstates: todayEstatesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}