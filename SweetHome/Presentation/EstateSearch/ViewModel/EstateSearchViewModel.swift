//
//  EstateSearchViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 9/3/25.
//

import Foundation
import RxSwift
import RxCocoa

class EstateSearchViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let searchQuery: Observable<String>
        let onAppear: Observable<Void>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let searchResults: Driver<[Estate]>
        let error: Driver<SHError>
        let isEmpty: Driver<Bool>
    }
    
    private let apiClient: ApiClient
    private let searchApiClient = ApiClient(network: NetworkService(interceptor: nil))
    
    init(apiClient: ApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let searchResultsRelay = BehaviorSubject<[Estate]>(value: [])
        let errorRelay = PublishSubject<SHError>()
        
        let searchTrigger = Observable.merge(
            input.onAppear.map { _ in "" },
            input.searchQuery.distinctUntilChanged()
        )
        
        let _ = searchTrigger
            .filter { !$0.isEmpty }
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] query -> Observable<[Estate]> in
                guard let self else { return Observable.error(SHError.commonError(.weakSelfFailure)) }

                return self.performSearch(query: query)
                    .catch { error -> Observable<[Estate]> in
                        errorRelay.onNext(SHError.from(error))
                        return Observable.just([])
                    }
            }
            .subscribe(onNext: { estates in
                searchResultsRelay.onNext(estates)
                isLoadingRelay.onNext(false)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        let isEmpty = searchResultsRelay
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            searchResults: searchResultsRelay.asDriver(onErrorJustReturn: []),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            isEmpty: isEmpty
        )
    }
    
    private func performSearch(query: String) -> Observable<[Estate]> {
        // TODO: Replace with actual API call
        // For now, return search result mock data filtered by query
        let mockResults = Estate.searchResultMock.filter { estate in
            estate.title.lowercased().contains(query.lowercased()) ||
            estate.category.lowercased().contains(query.lowercased()) ||
            estate.introduction.lowercased().contains(query.lowercased())
        }

        return Observable.just(mockResults.isEmpty ? Estate.searchResultMock : mockResults)
            .delay(.milliseconds(500), scheduler: MainScheduler.instance) // Simulate network delay
    }
}
