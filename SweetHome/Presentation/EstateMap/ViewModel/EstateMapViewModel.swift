//
//  EstateMapViewModel.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class EstateMapViewModel: ViewModelable {
    var disposeBag = DisposeBag()
    
    struct Input {
        let mapPositionChanged: Observable<(latitude: Double, longitude: Double, maxDistance: Int)>
        let estateTypeChanged: Observable<BannerEstateType>
        let estateSelected: Observable<Estate>
        let floatButtonTapped: Observable<Void>
        let filterChanged: Observable<(area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?)>
        let loadAllEstates: Observable<Void> // 전체 데이터 로드 트리거
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estates: Driver<[Estate]>
        let selectedEstate: Driver<Estate>
        let currentLocation: Driver<(latitude: Double, longitude: Double)>
        let error: Driver<SHError>
        let allEstatesLoaded: Driver<[Estate]> // 전체 데이터 로드 완료
    }
    
    // MARK: - Properties
    private let useCase: EstateMapUseCase
    private let locationService: LocationServiceProtocol
    private var currentEstateType: BannerEstateType = .oneRoom
    private var currentFilterValues: (area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?) = (nil, nil, nil)
    private var allEstates: [Estate] = []

    // MARK: - Initialization
    init(
        useCase: EstateMapUseCase = EstateMapUseCaseImpl(
            repository: EstateMapRepositoryImpl()
        ),
        locationService: LocationServiceProtocol = LocationService()
    ) {
        self.useCase = useCase
        self.locationService = locationService
    }
    
    deinit {
    }
    
    // MARK: - Cleanup
    func cleanup() {
        // 모든 진행 중인 Observable 체인 중단
        disposeBag = DisposeBag()
        
        // 저장된 데이터 정리
        allEstates.removeAll()
        currentFilterValues = (nil, nil, nil)
    }
    
    func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorSubject<Bool>(value: false)
        let estatesRelay = BehaviorSubject<[Estate]>(value: [])
        let selectedEstateRelay = PublishSubject<Estate>()
        let currentLocationRelay = PublishSubject<(latitude: Double, longitude: Double)>()
        let errorRelay = PublishSubject<SHError>()
        let allEstatesLoadedRelay = PublishSubject<[Estate]>()
        
        input.estateTypeChanged
            .subscribe(onNext: { [weak self] estateType in
                self?.currentEstateType = estateType
            })
            .disposed(by: disposeBag)
        
        // 전체 매물 데이터 로드 (한반도 전체 범위로 maxDistance 설정)
        input.loadAllEstates
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<[Estate]> in
                guard let self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }

                // 한반도 중심 좌표 (대한민국 중심부)
                let koreaCenter = (latitude: 36.5, longitude: 127.5)
                let maxDistance = 500000 // 500km (한반도 전체 커버)

                return self.useCase.fetchEstatesByLocation(
                    category: self.currentEstateType.rawValue,
                    latitude: String(koreaCenter.latitude),
                    longitude: String(koreaCenter.longitude),
                    maxDistance: maxDistance
                )
            }
            .subscribe(onNext: { [weak self] estates in
                self?.allEstates = estates
                allEstatesLoadedRelay.onNext(estates)
                isLoadingRelay.onNext(false)
            }, onError: { error in
                errorRelay.onNext(SHError.networkError(.connectionFailed("fail")))
                isLoadingRelay.onNext(false)
            })
            .disposed(by: disposeBag)
        
        input.filterChanged
            .subscribe(onNext: { [weak self] filterValues in
                self?.currentFilterValues = filterValues
                self?.applyFiltersAndUpdateEstates(estatesRelay: estatesRelay)
            })
            .disposed(by: disposeBag)
        
        input.mapPositionChanged
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] (latitude, longitude, maxDistance) -> Observable<[Estate]> in
                guard let self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }

                return self.useCase.fetchEstatesByLocation(
                    category: self.currentEstateType.rawValue,
                    latitude: String(latitude),
                    longitude: String(longitude),
                    maxDistance: maxDistance
                )
                .catch { error -> Observable<[Estate]> in
                    let estateError = SHError.estateError(.geoLocationFailed)
                    errorRelay.onNext(estateError)
                    return Observable.just([])
                }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(onNext: { [weak self] estates in
                self?.allEstates = estates
                self?.applyFiltersAndUpdateEstates(estatesRelay: estatesRelay)
            }, onError: { error in
                isLoadingRelay.onNext(false)
                errorRelay.onNext(SHError.from(error))
            })
            .disposed(by: disposeBag)
        
        input.estateSelected
            .subscribe(onNext: { estate in
                selectedEstateRelay.onNext(estate)
            })
            .disposed(by: disposeBag)
        
        input.floatButtonTapped
            .do(onNext: { _ in isLoadingRelay.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<(latitude: Double, longitude: Double)> in
                guard let self = self else {
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }
                
                return self.locationService.getCurrentLocation()
                    .catch { error -> Observable<(latitude: Double, longitude: Double)> in
                        let locationError = SHError.estateError(.invalidLocation)
                        errorRelay.onNext(locationError)
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(
                onNext: { location in
                    currentLocationRelay.onNext(location)
                },
                onError: { error in
                    isLoadingRelay.onNext(false)
                    errorRelay.onNext(SHError.from(error))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: isLoadingRelay.asDriver(onErrorDriveWith: .empty()),
            estates: estatesRelay.asDriver(onErrorDriveWith: .empty()),
            selectedEstate: selectedEstateRelay.asDriver(onErrorDriveWith: .empty()),
            currentLocation: currentLocationRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            allEstatesLoaded: allEstatesLoadedRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    // MARK: - Methods
    func updateEstateType(_ type: BannerEstateType) {
        currentEstateType = type
    }
    
    private func applyFiltersAndUpdateEstates(estatesRelay: BehaviorSubject<[Estate]>) {
        let filteredEstates = useCase.filterEstates(
            allEstates,
            areaFilter: currentFilterValues.area,
            monthlyPriceFilter: currentFilterValues.priceMonth,
            depositFilter: currentFilterValues.price
        )
        estatesRelay.onNext(filteredEstates)
    }
}
