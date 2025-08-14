//
//  EstateDetailViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/14/25.
//

import Foundation
import RxSwift
import RxCocoa

class EstateDetailViewModel: ViewModelable {
    let disposeBag = DisposeBag()
    
    struct Input {
        let viewDidLoad: Observable<String> // estateID
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estateDetail: Driver<DetailEstateResponse?>
        let error: Driver<SHError>
    }
    
    // MARK: - Properties
    private let apiClient: ApiClient
    
    // MARK: - Initialization
    init(apiClient: ApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let estateDetailRelay = BehaviorSubject<DetailEstateResponse?>(value: nil)
        let errorRelay = PublishSubject<SHError>()
        
        /// - 매물 상세정보 조회, EstateID를 받아 서버에 API호출
        input.viewDidLoad
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] estateID -> Observable<DetailEstateResponse> in
                guard let self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }
                
                return self.apiClient
                    .requestObservable(EstateEndpoint.detail(id: estateID))
                    .catch { error -> Observable<DetailEstateResponse> in
                        print(error.localizedDescription)
                        errorRelay.onNext(SHError.from(error))
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { detail in
                estateDetailRelay.onNext(detail)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            estateDetail: estateDetailRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
