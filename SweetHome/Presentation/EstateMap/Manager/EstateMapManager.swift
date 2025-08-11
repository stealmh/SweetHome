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
        positionChangeTimer?.invalidate()
        positionChangeTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        mapController?.pauseEngine()
        mapController?.resetEngine()
        removeObservers()
    }
    
    // MARK: - Properties for Map Tracking
    private var currentZoomLevel: Int = 0
    private var currentMapPosition: MapPoint?
    private var positionChangeTimer: Timer?  // 주기적 모니터링용
    private var delayTimer: Timer?           // 0.5초 딜레이용
    private var lastReportedPosition: MapPoint?
}

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
        
        // 줌 레벨 및 맵 이동 감지를 위한 이벤트 리스너 추가
        setupZoomLevelTracking(mapView: mapView)
        setupMapMoveTracking(mapView: mapView)
        
        /// - 델리게이트에게 맵 준비 완료 알림
        delegate?.mapDidFinishSetup()
    }
    
    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("❌ Map view failed to add: \(viewName)")
        delegate?.mapDidFailSetup(error: "Failed to add map view: \(viewName)")
    }
}

// MARK: - Map Tracking (Zoom & Move)
private extension EstateMapManager {
    
    /// - 줌 레벨 추적 설정
    func setupZoomLevelTracking(mapView: KakaoMap) {
        /// - 초기 줌 레벨 저장
        currentZoomLevel = Int(mapView.zoomLevel)
        print("📏 초기 zoom level: \(currentZoomLevel)")
    }
    
    /// - 맵 이동 추적 설정
    func setupMapMoveTracking(mapView: KakaoMap) {
        /// - 초기 맵 중심 좌표 저장
        currentMapPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        if let position = currentMapPosition {
            print("📍 초기 위치 - Lat: \(position.wgsCoord.latitude), Lng: \(position.wgsCoord.longitude)")
        }
        
        // 맵 이동 감지를 위한 타이머 시작
        startMapMoveMonitoring(mapView: mapView)
    }
    
    /// - 줌 레벨 변경 체크 (통합 모니터링에서 호출)
    func checkZoomLevelChange(mapView: KakaoMap) {
        let newZoomLevel = Int(mapView.zoomLevel)
        
        if newZoomLevel != currentZoomLevel {
            currentZoomLevel = newZoomLevel
            /// - 줌 변경도 위치 변경으로 간주하여 통합 타이머 사용
            triggerPositionChangeCheck(mapView: mapView)
        }
    }
    
    /// - 맵 이동 감지 시작 (위치 변화 기반 감지 - 제스처 충돌 방지)
    func startMapMoveMonitoring(mapView: KakaoMap) {
        /// - 0.2초마다 줌과 위치를 함께 체크
        positionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.monitorMapChanges(mapView: mapView)
        }
    }
    
    /// - 맵 변화 모니터링 (줌과 위치를 통합 체크)
    func monitorMapChanges(mapView: KakaoMap) {
        /// - 줌 레벨 변경 체크
        checkZoomLevelChange(mapView: mapView)
        
        /// - 위치 변경 체크
        let newPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        
        guard let currentPosition = currentMapPosition else {
            currentMapPosition = newPosition
            return
        }
        
        let latDiff = abs(newPosition.wgsCoord.latitude - currentPosition.wgsCoord.latitude)
        let lngDiff = abs(newPosition.wgsCoord.longitude - currentPosition.wgsCoord.longitude)
        
        /// - 위치가 변했다면 (아주 작은 변화도 감지)
        if latDiff > 0.0000001 || lngDiff > 0.0000001 {
            // 위치 변화 감지
            triggerPositionChangeCheck(mapView: mapView)
        }
    }
    
    /// - 위치 변경 체크 트리거 (줌/드래그 공통)
    func triggerPositionChangeCheck(mapView: KakaoMap) {
        /// - 기존 딜레이 타이머가 있다면 취소
        delayTimer?.invalidate()
        delayTimer = nil
        
        /// - 현재 위치 업데이트
        currentMapPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        
        /// - 0.5초 후에 최종 위치 체크 (별도 타이머 사용)
        delayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.checkFinalMapPosition(mapView: mapView)
        }
    }
    
    /// - 드래그 완료 후 최종 위치 체크 (의미있는 변화만)
    func checkFinalMapPosition(mapView: KakaoMap) {
        let finalPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        
        /// - 줌 레벨에 따른 의미있는 움직임인지 체크
        let threshold = getMovementThreshold(for: currentZoomLevel)
        
        if let lastReportedPosition = lastReportedPosition {
            let latDiff = abs(finalPosition.wgsCoord.latitude - lastReportedPosition.wgsCoord.latitude)
            let lngDiff = abs(finalPosition.wgsCoord.longitude - lastReportedPosition.wgsCoord.longitude)
            
            if latDiff > threshold || lngDiff > threshold {
                self.lastReportedPosition = finalPosition
                onMapMoveCompleted(position: finalPosition)
            }
        } else {
            self.lastReportedPosition = finalPosition
            onMapMoveCompleted(position: finalPosition)
        }
    }
    
    
    /// - 맵 이동 완료 시 호출 (마커 업데이트를 위한 좌표 출력)
    func onMapMoveCompleted(position: MapPoint) {
        print("🗺️ Map position changed - Lat: \(position.wgsCoord.latitude), Lng: \(position.wgsCoord.longitude)")
        print("📍 Ready to fetch markers for current location with \(calculateMaxDistance(from: currentZoomLevel))m radius")
        
        // TODO: 여기서 새로운 위치 기준으로 마커 데이터를 API로 요청할 예정
        // delegate?.mapPositionChanged(latitude: position.wgsCoord.latitude, longitude: position.wgsCoord.longitude, maxDistance: calculateMaxDistance(from: currentZoomLevel))
    }
    
    /// - 줌 레벨에 따른 움직임 인식 임계값 계산
    func getMovementThreshold(for zoomLevel: Int) -> Double {
        switch zoomLevel {
        case 0...5:   return 0.01    // 광역 뷰 - 큰 움직임만 감지 (약 1km)
        case 6...8:   return 0.005   // 도시 뷰 - 중간 움직임 감지 (약 500m)
        case 9...11:  return 0.002   // 구역 뷰 - 작은 움직임 감지 (약 200m)
        case 12...14: return 0.001   // 상세 뷰 - 세밀한 움직임 감지 (약 100m)
        default:      return 0.0005  // 최대 확대 - 매우 세밀한 움직임 감지 (약 50m)
        }
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
