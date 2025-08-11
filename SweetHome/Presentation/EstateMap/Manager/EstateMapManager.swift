//
//  EstateMapManager.swift
//  SweetHome
//
//  Created by 김민호 on 8/11/25.
//

import UIKit
import KakaoMapsSDK
import SnapKit

/// - 지도 관련 기능을 관리하는 매니저 클래스
class EstateMapManager: NSObject {
    
    // MARK: - Properties
    private var mapContainer: KMViewContainer?
    private var mapController: KMController?
    private var _observerAdded: Bool = false
    private var _auth: Bool = false
    private var _appear: Bool = false
    
    /// - 맵 매니저 델리게이트
    weak var delegate: EstateMapManagerDelegate?
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// - 맵 컨테이너를 설정하고 초기화
    func setupMapContainer(in parentView: UIView, below searchView: UIView) -> KMViewContainer? {
        mapContainer = KMViewContainer()
        mapContainer?.backgroundColor = .clear
        
        guard let container = mapContainer else { return nil }
        
        parentView.addSubview(container)
        container.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom)
            $0.leading.trailing.bottom.equalTo(parentView.safeAreaLayoutGuide)
        }
        
        mapController = KMController(viewContainer: container)
        mapController?.delegate = self
        mapController?.prepareEngine()
        
        return container
    }
    
    /// - 앱 생명주기에 따른 맵 엔진 관리
    func viewWillAppear() {
        addObservers()
        _appear = true
        
        if mapController?.isEnginePrepared == false {
            mapController?.prepareEngine()
        }
        
        if mapController?.isEngineActive == false {
            mapController?.activateEngine()
        }
    }
    
    func viewWillDisappear() {
        _appear = false
        mapController?.pauseEngine()
    }
    
    func viewDidDisappear() {
        removeObservers()
        mapController?.resetEngine()
    }
    
    /// - 맵 컨테이너 반환
    func getMapContainer() -> KMViewContainer? {
        return mapContainer
    }
    
    /// - 정리 작업
    func cleanup() {
        zoomTimer?.invalidate()
        zoomTimer = nil
        mapController?.pauseEngine()
        mapController?.resetEngine()
        removeObservers()
    }
}

// MARK: - Properties for Zoom Tracking
private var currentZoomLevel: Int = 0
private var zoomTimer: Timer?

// MARK: - MapControllerDelegate
extension EstateMapManager: MapControllerDelegate {
    
    func authenticationSucceeded() {
        print("🔐 authenticationSucceeded called")
        
        if _auth == false {
            _auth = true
            print("🔐 Auth status changed to true")
        }
        
        if _appear && mapController?.isEngineActive == false {
            mapController?.activateEngine()
            print("🔐 Engine activated")
        }
        
        addViews()
    }
    
    /// - 맵 뷰를 추가 (MapControllerDelegate 프로토콜 요구사항)
    func addViews() {
        print("🗺️ addViews() called")
        
        let defaultPosition: MapPoint = MapPoint(longitude: 127.108678, latitude: 37.402001)
        let mapviewInfo: MapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition, defaultLevel: 7)
        
        mapController?.addView(mapviewInfo)
    }
    
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        print("✅ addViewSucceeded called for \(viewName)")
        
        guard let mapView = mapController?.getView("mapview") as? KakaoMap,
              let container = mapContainer else {
            print("❌ Error: mapView or mapContainer is nil")
            return
        }
        
        mapView.viewRect = container.bounds
        
        // 줌 레벨 변경 감지를 위한 이벤트 리스너 추가
        setupZoomLevelTracking(mapView: mapView)
        
        /// - 델리게이트에게 맵 준비 완료 알림
        delegate?.mapDidFinishSetup()
    }
    
    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("❌ Map view failed to add: \(viewName)")
        delegate?.mapDidFailSetup(error: "Failed to add map view: \(viewName)")
    }
}

// MARK: - Zoom Level Tracking
private extension EstateMapManager {
    
    /// - 줌 레벨 추적 설정
    func setupZoomLevelTracking(mapView: KakaoMap) {
        // 초기 줌 레벨 저장
        currentZoomLevel = Int(mapView.zoomLevel)
        print("📏 Initial zoom level: \(currentZoomLevel)")
        
        // 줌 레벨 변경 감지를 위한 타이머 시작
        startZoomLevelMonitoring(mapView: mapView)
    }
    
    /// - 줌 레벨 모니터링 시작
    func startZoomLevelMonitoring(mapView: KakaoMap) {
        // 기존 타이머가 있다면 정리
        zoomTimer?.invalidate()
        
        // 0.1초마다 줌 레벨 체크
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkZoomLevelChange(mapView: mapView)
        }
    }
    
    /// - 줌 레벨 변경 체크
    func checkZoomLevelChange(mapView: KakaoMap) {
        let newZoomLevel = Int(mapView.zoomLevel)
        
        if newZoomLevel != currentZoomLevel {
            currentZoomLevel = newZoomLevel
            onZoomLevelChanging(zoomLevel: newZoomLevel)
        }
    }
    
    /// - 줌 레벨 변경 중일 때 호출
    func onZoomLevelChanging(zoomLevel: Int) {
        // 이전 타이머 무효화
        zoomTimer?.invalidate()
        
        // 0.5초 후에 줌 변경이 완료되었다고 간주
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.onZoomLevelChangeCompleted(zoomLevel: zoomLevel)
        }
    }
    
    /// - 줌 레벨 변경 완료 시 호출
    func onZoomLevelChangeCompleted(zoomLevel: Int) {
        print("🔍 Zoom level changed to: \(zoomLevel)")
        
        // maxDistance 계산
        let maxDistance = calculateMaxDistance(from: zoomLevel)
        print("📍 Max search distance: \(maxDistance)m")
        
        // 모니터링 재시작
        guard let mapView = mapController?.getView("mapview") as? KakaoMap else { return }
        startZoomLevelMonitoring(mapView: mapView)
    }
    
    /// - 줌 레벨로부터 최대 검색 거리 계산
    func calculateMaxDistance(from zoomLevel: Int) -> Int {
        switch zoomLevel {
        case 0...5: return 10000    // 10km
        case 6...8: return 5000     // 5km
        case 9...11: return 2000    // 2km
        case 12...14: return 1000   // 1km
        default: return 500         // 500m
        }
    }
}

// MARK: - Private Methods
private extension EstateMapManager {
    
    /// - 알림 관찰자 추가
    func addObservers() {
        guard !_observerAdded else { return }
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        _observerAdded = true
    }
    
    /// - 알림 관찰자 제거
    func removeObservers() {
        guard _observerAdded else { return }
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        _observerAdded = false
    }
    
    /// - 앱이 비활성화될 때
    @objc func willResignActive() {
        mapController?.pauseEngine()
    }
    
    /// - 앱이 활성화될 때
    @objc func didBecomeActive() {
        mapController?.activateEngine()
    }
}

// MARK: - EstateMapManagerDelegate
protocol EstateMapManagerDelegate: AnyObject {
    /// - 맵 설정이 완료되었을 때 호출
    func mapDidFinishSetup()
    
    /// - 맵 설정이 실패했을 때 호출
    func mapDidFailSetup(error: String)
}