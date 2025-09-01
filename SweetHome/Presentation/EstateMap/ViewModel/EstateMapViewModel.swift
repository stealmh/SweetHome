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
        let estateSelected: Observable<EstateGeoLocationDataResponse>
        let floatButtonTapped: Observable<Void>
        let filterChanged: Observable<(area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?)>
    }
    
    struct Output: ViewModelLoadable, ViewModelErrorable {
        let isLoading: Driver<Bool>
        let estates: Driver<[EstateGeoLocationDataResponse]>
        let selectedEstate: Driver<EstateGeoLocationDataResponse>
        let currentLocation: Driver<(latitude: Double, longitude: Double)>
        let error: Driver<SHError>
    }
    
    // MARK: - Properties
    private let apiClient: ApiClient
    private let locationService: LocationServiceProtocol
    private var currentEstateType: BannerEstateType = .oneRoom
    private var currentFilterValues: (area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?) = (nil, nil, nil)
    private var allEstates: [EstateGeoLocationDataResponse] = []
    
    // MARK: - Initialization
    init(apiClient: ApiClient = ApiClient.shared, locationService: LocationServiceProtocol = LocationService()) {
        self.apiClient = apiClient
        self.locationService = locationService
    }
    
    deinit {
        print("EstateMapViewModel deinit")
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
        let estatesRelay = BehaviorSubject<[EstateGeoLocationDataResponse]>(value: [])
        let selectedEstateRelay = PublishSubject<EstateGeoLocationDataResponse>()
        let currentLocationRelay = PublishSubject<(latitude: Double, longitude: Double)>()
        let errorRelay = PublishSubject<SHError>()
        
        input.estateTypeChanged
            .subscribe(onNext: { [weak self] estateType in
                self?.currentEstateType = estateType
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
            .flatMapLatest { [weak self] (latitude, longitude, maxDistance) -> Observable<[EstateGeoLocationDataResponse]> in
                guard let self else { 
                    return Observable.error(SHError.commonError(.weakSelfFailure))
                }
                
                let request = EstateGeoLocationRequest(
                    category: self.currentEstateType.rawValue,
                    longitude: String(longitude),
                    latitude: String(latitude),
                    maxDistance: maxDistance
                )
                
                return self.apiClient
                    .requestObservable(EstateEndpoint.geoLocation(parameter: request))
                    .map { (response: EstateGeoLocationResponse) -> [EstateGeoLocationDataResponse] in
                        response.data
                    }
                    .catch { error -> Observable<[EstateGeoLocationDataResponse]> in
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
                        print("❌ Location error: \(error)")
                        let locationError = SHError.estateError(.invalidLocation)
                        errorRelay.onNext(locationError)
                        return Observable.empty()
                    }
            }
            .do(onNext: { _ in isLoadingRelay.onNext(false) })
            .subscribe(
                onNext: { location in
                    print("📍 Current location received: \(location.latitude), \(location.longitude)")
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
            error: errorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
    
    // MARK: - Methods
    func updateEstateType(_ type: BannerEstateType) {
        currentEstateType = type
    }
    
    private func applyFiltersAndUpdateEstates(estatesRelay: BehaviorSubject<[EstateGeoLocationDataResponse]>) {
        let filteredEstates = filterEstates(allEstates)
        estatesRelay.onNext(filteredEstates)
    }
    
    private func filterEstates(_ estates: [EstateGeoLocationDataResponse]) -> [EstateGeoLocationDataResponse] {
        guard hasActiveFilters() else {
            return estates
        }
        
        return estates.filter { estate in
            return passesAreaFilter(estate) && 
                   passesMonthlyPriceFilter(estate) && 
                   passesDepositFilter(estate)
        }
    }
    
    private func hasActiveFilters() -> Bool {
        return currentFilterValues.area != nil || 
               currentFilterValues.priceMonth != nil || 
               currentFilterValues.price != nil
    }
    
    private func passesAreaFilter(_ estate: EstateGeoLocationDataResponse) -> Bool {
        guard let areaFilter = currentFilterValues.area else { return true }
        
        let estateArea = Float(estate.area)
        let estateAreaPyeong = estateArea * 0.3025  // m² to 평 conversion
        
        return estateAreaPyeong >= areaFilter.0 && estateAreaPyeong <= areaFilter.1
    }
    
    private func passesMonthlyPriceFilter(_ estate: EstateGeoLocationDataResponse) -> Bool {
        guard let priceFilter = currentFilterValues.priceMonth else { return true }
        
        // 서버에서 1원 단위로 전송되므로 만원 단위로 변환
        let monthlyPriceManWon = Float(estate.monthly_rent) / 10000
        
        // 최대값(200만원)을 선택했을 때는 그보다 큰 값도 포함
        if priceFilter.1 >= 200 {
            return monthlyPriceManWon >= priceFilter.0
        } else {
            return monthlyPriceManWon >= priceFilter.0 && monthlyPriceManWon <= priceFilter.1
        }
    }
    
    private func passesDepositFilter(_ estate: EstateGeoLocationDataResponse) -> Bool {
        guard let depositFilter = currentFilterValues.price else { return true }
        
        // 서버에서 1원 단위로 전송되므로 만원 단위로 변환
        let depositManWon = Float(estate.deposit) / 10000
        
        // 최대값(1억 = 10000만원)을 선택했을 때는 그보다 큰 값(예: 5억)도 포함
        if depositFilter.1 >= 10000 {
            return depositManWon >= depositFilter.0
        } else {
            return depositManWon >= depositFilter.0 && depositManWon <= depositFilter.1
        }
    }
}
