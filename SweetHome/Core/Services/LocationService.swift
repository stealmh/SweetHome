//
//  LocationService.swift
//  SweetHome
//
//  Created by 김민호 on 8/13/25.
//

import Foundation
import CoreLocation
import RxSwift

protocol LocationServiceProtocol {
    /// 현재 위치를 가져오는 메서드
    func getCurrentLocation() -> Observable<(latitude: Double, longitude: Double)>
    
    /// 위치 권한 요청
    func requestLocationPermission() -> Observable<CLAuthorizationStatus>
    
    /// 현재 위치 권한 상태
    var authorizationStatus: CLAuthorizationStatus { get }
}

class LocationService: NSObject, LocationServiceProtocol {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    private let locationSubject = PublishSubject<(latitude: Double, longitude: Double)>()
    private let authorizationSubject = PublishSubject<CLAuthorizationStatus>()
    
    // MARK: - Computed Properties
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 업데이트
    }
    
    // MARK: - Public Methods
    func getCurrentLocation() -> Observable<(latitude: Double, longitude: Double)> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SHError.locationError(.serviceUnavailable))
                return Disposables.create()
            }
            
            // 권한 체크
            switch self.authorizationStatus {
            case .notDetermined:
                // 권한 요청 후 권한 상태 변경을 기다림
                let authorizationDisposable = self.authorizationSubject
                    .take(1)
                    .subscribe(onNext: { status in
                        switch status {
                        case .authorizedWhenInUse, .authorizedAlways:
                            self.locationManager.requestLocation()
                        case .denied, .restricted:
                            observer.onError(SHError.locationError(.permissionDenied))
                        default:
                            observer.onError(SHError.locationError(.unknown))
                        }
                    })
                
                // 권한 요청
                self.locationManager.requestWhenInUseAuthorization()
                
                // 위치 결과 구독
                let locationDisposable = self.locationSubject
                    .take(1)
                    .subscribe(
                        onNext: { location in
                            observer.onNext(location)
                            observer.onCompleted()
                        },
                        onError: { error in
                            observer.onError(error)
                        }
                    )
                
                return CompositeDisposable(authorizationDisposable, locationDisposable)
                
            case .denied, .restricted:
                observer.onError(LocationError.permissionDenied)
                return Disposables.create()
                
            case .authorizedWhenInUse, .authorizedAlways:
                // 위치 요청
                self.locationManager.requestLocation()
                
                // 위치 결과 구독
                let subscription = self.locationSubject
                    .take(1)
                    .subscribe(
                        onNext: { location in
                            observer.onNext(location)
                            observer.onCompleted()
                        },
                        onError: { error in
                            observer.onError(error)
                        }
                    )
                
                return subscription
                
            @unknown default:
                observer.onError(LocationError.unknown)
                return Disposables.create()
            }
        }
    }
    
    func requestLocationPermission() -> Observable<CLAuthorizationStatus> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(SHError.locationError(.serviceUnavailable))
                return Disposables.create()
            }
            
            // 현재 상태가 이미 결정되어 있다면 즉시 반환
            if self.authorizationStatus != .notDetermined {
                observer.onNext(self.authorizationStatus)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 권한 상태 변경 구독
            let subscription = self.authorizationSubject
                .take(1)
                .subscribe(
                    onNext: { status in
                        observer.onNext(status)
                        observer.onCompleted()
                    },
                    onError: { error in
                        observer.onError(error)
                    }
                )
            
            // 권한 요청
            self.locationManager.requestWhenInUseAuthorization()
            
            return subscription
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📍 Current location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        locationSubject.onNext((
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error)")
        locationSubject.onError(SHError.locationError(.locationFailed(error)))
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Location authorization changed: \(status.rawValue)")
        authorizationSubject.onNext(status)
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationFailed(Error)
    case serviceUnavailable
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "위치 접근 권한이 거부되었습니다."
        case .locationFailed(let error):
            return "위치 정보를 가져오는데 실패했습니다: \(error.localizedDescription)"
        case .serviceUnavailable:
            return "위치 서비스를 사용할 수 없습니다."
        case .unknown:
            return "알 수 없는 위치 오류가 발생했습니다."
        }
    }
}
