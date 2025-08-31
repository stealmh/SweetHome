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
    
    /// - 마커 관련
    private var labelManager: LabelManager?
    private var estateLodLayer: LodLabelLayer?
    private var currentEstateMarkers: [String: LodPoi] = [:]  // estate_id : LodPoi 매핑
    private var markerAnimator: PoiAnimator?
    
    /// - 이미지 캐시 (메모리 최적화)
    private var imageCache: [String: UIImage] = [:]
    private let maxCacheSize = 50 // 최대 캐시 이미지 수
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    deinit {
        print("EstateMapManager deinit")
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
            $0.leading.trailing.equalTo(parentView.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
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
//        mapController?.resetEngine()
    }
    
    /// - 맵 컨테이너 반환
    func getMapContainer() -> KMViewContainer? {
        return mapContainer
    }
    
    /// - 정리 작업
    func cleanup() {
        clearAllEstateMarkers()
        labelManager = nil
        estateLodLayer = nil
        markerAnimator = nil
        currentEstateMarkers.removeAll()
        imageCache.removeAll() // 이미지 캐시 정리
        positionChangeTimer?.invalidate()
        positionChangeTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
//        mapController?.pauseEngine()
        mapController?.resetEngine()
//        removeObservers()
    }
    
    /// - 현재 줌 레벨 반환
    func getCurrentZoomLevel() -> Int {
        return currentZoomLevel
    }
    
    
    // MARK: - Properties for Map Tracking
    private var currentZoomLevel: Int = 0
    private var currentMapPosition: MapPoint?
    private var positionChangeTimer: Timer?  // 주기적 모니터링용
    private var delayTimer: Timer?           // 0.5초 딜레이용
    private var lastReportedPosition: MapPoint?
    private var isUpdatingMarkers: Bool = false  // 마커 업데이트 진행 중 플래그
    
    //MARK: - 클러스터링 데이터 구조
    private var clusterData: [String: [EstateGeoLocationDataResponse]] = [:] // 위치별 매물 그룹
    private var clusterMarkers: [String: LodPoi] = [:] // 클러스터 마커들
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
        
        let defaultPosition: MapPoint = MapPoint(longitude: 126.88687510570243, latitude: 37.51765394494029)
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
            let oldZoomLevel = currentZoomLevel
            currentZoomLevel = newZoomLevel
            
            print("🔍 Zoom level changed: \(oldZoomLevel) -> \(newZoomLevel)")
            
            // 클러스터링 전략이 변경되었는지 확인
            if shouldUpdateClustering(newZoomLevel: newZoomLevel) {
                if newZoomLevel >= 13 || oldZoomLevel >= 13 {
                    print("🔄 Estate marker scale update needed - will update markers")
                } else {
                    print("🔄 Clustering strategy changed - will update markers")
                }
            }
            
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
    
    /// - 맵 변화 모니터링 (최적화된 버전)
    func monitorMapChanges(mapView: KakaoMap) {
        // 마커 업데이트 중이면 모니터링 스킵
        guard !isUpdatingMarkers else { return }
        
        /// - 줌 레벨 변경 체크
        checkZoomLevelChange(mapView: mapView)
        
        /// - 위치 변경 체크 (임계값 확대)
        let newPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        
        guard let currentPosition = currentMapPosition else {
            currentMapPosition = newPosition
            return
        }
        
        let latDiff = abs(newPosition.wgsCoord.latitude - currentPosition.wgsCoord.latitude)
        let lngDiff = abs(newPosition.wgsCoord.longitude - currentPosition.wgsCoord.longitude)
        
        // 임계값을 높여서 불필요한 업데이트 방지
        let threshold = 0.000001 // 기존 0.0000001에서 10배 증가
        
        if latDiff > threshold || lngDiff > threshold {
            triggerPositionChangeCheck(mapView: mapView)
        }
    }
    
    /// - 위치 변경 체크 트리거 (줌/드래그 공통) - 최적화
    func triggerPositionChangeCheck(mapView: KakaoMap) {
        // 마커 업데이트 중이면 무시
        guard !isUpdatingMarkers else {
            print("⏳ Skipping position change check - markers updating")
            return
        }
        
        /// - 기존 딜레이 타이머가 있다면 취소
        delayTimer?.invalidate()
        delayTimer = nil
        
        /// - 현재 위치 업데이트
        currentMapPosition = mapView.getPosition(CGPoint(x: mapView.viewRect.width/2, y: mapView.viewRect.height/2))
        
        /// - 딜레이 시간 단축 (0.5초 -> 0.3초)
        delayTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
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
        
        delegate?.mapPositionChanged(
            latitude: position.wgsCoord.latitude,
            longitude: position.wgsCoord.longitude,
            maxDistance: calculateMaxDistance(from: currentZoomLevel)
        )
    }
    
    /// - 줌 레벨에 따른 움직임 인식 임계값 계산
    func getMovementThreshold(for zoomLevel: Int) -> Double {
        switch zoomLevel {
        case 0...6:   return 0.05    // 국가/한반도 뷰 - 매우 큰 움직임만 감지 (약 5km)
        case 7...9:   return 0.02    // 광역시/도 뷰 - 큰 움직임 감지 (약 2km)
        case 10...12: return 0.008   // 시/군 뷰 - 중간 움직임 감지 (약 800m)
        case 13...15: return 0.003   // 구/동 뷰 - 작은 움직임 감지 (약 300m)
        case 16...18: return 0.001   // 상세 뷰 - 세밀한 움직임 감지 (약 100m)
        default:      return 0.0005  // 최대 확대 - 매우 세밀한 움직임 감지 (약 50m)
        }
    }
    
    /// - 줌 레벨로부터 최대 검색 거리 계산 (한국 지도 기준 최적화)
    public func calculateMaxDistance(from zoomLevel: Int) -> Int {
        switch zoomLevel {
        case 0...6:   return 100000  // 100km (한반도/전국 뷰)
        case 7...8:   return 50000   // 50km (광역시/도 뷰)
        case 9...10:  return 25000   // 25km (시/군 뷰) 
        case 11...12: return 10000   // 10km (구 단위)
        case 13...14: return 5000    // 5km (여러 동)
        case 15...16: return 2000    // 2km (동 단위)
        case 17...18: return 1000    // 1km (상세 지역)
        default:      return 500     // 500m (최대 상세)
        }
    }
    
    /// - 지도를 특정 위치로 이동
    public func moveToLocation(latitude: Double, longitude: Double, animated: Bool = false) {
        // 메인 스레드에서 실행 보장
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let mapController = self.mapController,
                  let mapView = mapController.getView("mapview") as? KakaoMap else {
                print("❌ Map controller or view not available for movement")
                return
            }
            
            // 지도가 준비되었는지 확인
            guard mapController.isEngineActive else {
                print("❌ Map engine is not active yet")
                // 잠시 후 재시도
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.moveToLocation(latitude: latitude, longitude: longitude, animated: animated)
                }
                return
            }
            
            let position = MapPoint(longitude: longitude, latitude: latitude)
            
            if animated {
                // 애니메이션과 함께 이동
                let cameraUpdate = CameraUpdate.make(target: position, mapView: mapView)
                mapView.moveCamera(cameraUpdate)
                print("📍 Map moved to location: \(latitude), \(longitude) with animation")
            } else {
                // 즉시 이동
                let cameraUpdate = CameraUpdate.make(target: position, mapView: mapView)
                mapView.moveCamera(cameraUpdate)
                print("📍 Map moved to location: \(latitude), \(longitude) immediately")
            }
        }
    }
    
    /// - 매물 데이터로 마커 업데이트 (최적화된 버전)
    public func updateEstateMarkers(with estates: [EstateGeoLocationDataResponse]) {
        // 매물 개수 제한 (성능 및 안정성을 위해)
        let maxEstates = getMaxEstatesForZoomLevel(currentZoomLevel)
        let limitedEstates = Array(estates.prefix(maxEstates))
        
        if estates.count > maxEstates {
            print("⚠️ 매물 개수 제한: \(estates.count) → \(limitedEstates.count)개 (줌 레벨: \(currentZoomLevel))")
        } else {
            print("📍 현재 위치 매물: \(limitedEstates.count)개, 줌 레벨: \(currentZoomLevel)")
        }
        
        // 중복 업데이트 방지
        guard !isUpdatingMarkers else {
            return
        }
        
        // 동일한 데이터인지 확인하여 불필요한 업데이트 방지
        if areEstatesSame(newEstates: limitedEstates) {
            return
        }
        
        guard let mapView = mapController?.getView("mapview") as? KakaoMap else {
            return
        }
        
        isUpdatingMarkers = true
        
        // 마커 시스템 초기화 (한 번만)
        if estateLodLayer == nil {
            setupEstateMarkerSystem(mapView: mapView)
        }
        
        // 즉시 마커 업데이트 (딜레이 제거)
        processMarkerUpdateOptimized(with: limitedEstates)
    }
    
    /// - 최적화된 마커 업데이트 처리
    private func processMarkerUpdateOptimized(with estates: [EstateGeoLocationDataResponse]) {
        print("🔄 마커 업데이트 시작 - 기존 마커 정리")
        
        // 기존 마커 완전 정리
        clearAllEstateMarkersSync()
        
        // 짧은 지연으로 정리 작업 완료 보장
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            print("🔄 새로운 마커 생성 시작")
            
            // 새 마커 생성
            self?.createEstateMarkersOptimized(from: estates)
            
            // 마커 업데이트 완료 플래그 해제
            self?.isUpdatingMarkers = false
            
            print("🔄 마커 업데이트 완료")
        }
    }
    
    /// - 매물 데이터 변경 여부 확인
    private func areEstatesSame(newEstates: [EstateGeoLocationDataResponse]) -> Bool {
        let currentIds = Set(currentEstateMarkers.keys)
        let newIds = Set(newEstates.map { "estate_\($0.estate_id)" })
        return currentIds == newIds && currentIds.count == newEstates.count
    }
    
    /// - 모든 매물 마커 제거 (기존 버전)
    func clearAllEstateMarkers() {
        print("🧹 전체 마커 정리 시작: 클러스터 \(clusterMarkers.count)개, 개별 \(currentEstateMarkers.count)개")
        
        // 1. 개별 POI들을 명시적으로 제거
        var removedPois: [LodPoi] = []
        
        // 개별 마커 참조 정리
        for (key, poi) in currentEstateMarkers {
            poi.hide()
            removedPois.append(poi)
            print("🧹   개별 마커 제거: \(key)")
        }
        currentEstateMarkers.removeAll()
        
        // 클러스터 마커 참조 정리
        for (key, poi) in clusterMarkers {
            poi.hide()
            removedPois.append(poi)
            print("🧹   클러스터 마커 제거: \(key)")
        }
        clusterMarkers.removeAll()
        clusterData.removeAll()
        
        // 2. LOD 레이어에서 POI들 완전 제거
        if let lodLayer = estateLodLayer {
            // 모든 POI 숨기기
            lodLayer.hideAllLodPois()
            
            // 개별 POI들을 LOD Layer에서 제거
            for poi in removedPois {
                lodLayer.removeLodPoi(poiID: poi.itemID)
            }
            
            print("🧹 LOD Layer에서 \(removedPois.count)개 POI 제거 완료")
        }
        
        print("🧹 전체 마커 정리 완료")
    }
    
    /// - 동기식 마커 정리 (깜빡임 최소화)
    private func clearAllEstateMarkersSync() {
        print("🧹 마커 정리 시작: 클러스터 \(clusterMarkers.count)개, 개별 \(currentEstateMarkers.count)개")
        
        // 1. 개별 POI들을 명시적으로 제거
        var removedPois: [LodPoi] = []
        for (key, poi) in currentEstateMarkers {
            poi.hide()
            removedPois.append(poi)
            print("🧹   개별 마커 제거: \(key)")
        }
        for (key, poi) in clusterMarkers {
            poi.hide() 
            removedPois.append(poi)
            print("🧹   클러스터 마커 제거: \(key)")
        }
        
        // 2. LOD Layer에서 POI들 제거
        if let lodLayer = estateLodLayer {
            // 모든 POI 숨기기
            lodLayer.hideAllLodPois()
            
            // 개별 POI들을 LOD Layer에서 제거 시도
            for poi in removedPois {
                lodLayer.removeLodPoi(poiID: poi.itemID)
            }
            
            print("🧹 LOD Layer에서 \(removedPois.count)개 POI 제거 완료")
        }
        
        // 3. 참조 정리
        currentEstateMarkers.removeAll()
        clusterMarkers.removeAll()
        clusterData.removeAll()
        
        print("🧹 마커 정리 완료")
    }
    
    /// - 마커 업데이트 전 줌 레벨 체크
    func shouldUpdateClustering(newZoomLevel: Int) -> Bool {
        let oldLevel = currentZoomLevel
        
        // 줌 레벨이 전략 바뀜 경계를 넘나갔을 때 클러스터링 업데이트
        let oldStrategy = getClusteringStrategy(for: oldLevel)
        let newStrategy = getClusteringStrategy(for: newZoomLevel)
        
        // 개별 매물 마커가 표시되는 줌 레벨에서는 스케일 변화를 위해 더 자주 업데이트
        let shouldUpdateForEstateMarkerScale = (oldLevel >= 13 || newZoomLevel >= 13) && oldLevel != newZoomLevel
        
        return oldStrategy != newStrategy || shouldUpdateForEstateMarkerScale
    }
    
    /// - 줌 레벨에 따른 클러스터링 전략 반환 (명확한 구분)
    func getClusteringStrategy(for zoomLevel: Int) -> ClusteringStrategy {
        switch zoomLevel {
        case 0...12:  return .grid      // 광역~구 뷰 - 클러스터만 표시
        case 13...15: return .distance  // 동네 단위 - 클러스터 + 일부 개별 마커
        default:      return .none      // 상세 뷰 (16+) - 개별 마커만 표시
        }
    }
}

// MARK: - Private Methods
private extension EstateMapManager {
    
    /// - 매물 마커 시스템 설정 (POI 패턴 적용)
    func setupEstateMarkerSystem(mapView: KakaoMap) {
        labelManager = mapView.getLabelManager()
        
        guard let manager = labelManager else {
            print("❌ Failed to get label manager")
            return
        }
        
        // 매물 마커 스타일들 생성
        createEstateMarkerStyles(manager: manager)
        
        // 마커 애니메이션 설정
        setupMarkerAnimations(manager: manager)
        
        // LOD 레이어 설정 (클러스터링 적용)
        setupEstateLodLayer(manager: manager)
    }
    
    /// - 매물 마커 스타일들 생성 (다양한 타입별 + 커스텀 UIView)
    func createEstateMarkerStyles(manager: LabelManager) {
        /// - 기본 마커
        createEstateMarkerStyle(manager: manager, styleID: "estate_default", color: .systemBlue)
        
        /// - 클러스터 마커
        createClusterMarkerStyles(manager: manager)
        
        print("✅ Estate marker styles created with zoom level control:")
        print("   📍 Clusters: Zoom 0-14")
        print("   🏠 Basic markers: Zoom 10-14") 
        print("   🖼️ Custom thumbnail markers: Zoom 15+")
    }
    
    /// - UIView를 이미지로 변환하여 마커 스타일 생성
    func createMarkerStyleFromView(manager: LabelManager, view: UIView, styleID: String, completion: (() -> Void)? = nil) {
        // CustomEstateMarkerView의 경우 고정 크기 사용 (Auto Layout 기반)
        let targetSize: CGSize
        if view is CustomEstateMarkerView {
            // CustomEstateMarkerView의 내부 제약조건 기반 크기
            targetSize = CGSize(width: 72, height: 100) // 고정 크기
        } else {
            // 다른 뷰는 systemLayoutSizeFitting 사용
            view.setNeedsLayout()
            view.layoutIfNeeded()
            targetSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        
        view.frame = CGRect(origin: .zero, size: targetSize)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // CustomEstateMarkerView인 경우 이미지 로딩 완료를 기다림
        if let markerView = view as? CustomEstateMarkerView {
            markerView.onImageLoaded = { [weak self] in
                DispatchQueue.main.async {
                    print("🔄 이미지 로딩 완료, 마커 스타일 생성 시작: \(styleID)")
                    
                    // 이미지 로딩 완료 후 마커 스타일 생성
                    markerView.setNeedsLayout()
                    markerView.layoutIfNeeded()
                    
                    let finalImage = self?.createImageFromView(view: markerView, size: targetSize) ?? UIImage()
                    print("🖼️ 최종 마커 이미지 크기: \(finalImage.size)")
                    
                    let iconStyle = PoiIconStyle(
                        symbol: finalImage,
                        anchorPoint: CGPoint(x: 0.5, y: 0.5)
                    )
                    
                    let emptyTextStyle = PoiTextStyle(textLineStyles: [])
                    let perLevelStyle = PerLevelPoiStyle(
                        iconStyle: iconStyle,
                        textStyle: emptyTextStyle,
                        level: 15
                    )
                    
                    let poiStyle = PoiStyle(styleID: styleID, styles: [perLevelStyle])
                    manager.addPoiStyle(poiStyle)
                    
                    print("✅ 이미지 로딩 완료 후 마커 스타일 생성: \(styleID)")
                    completion?()
                }
            }
        } else {
            // CustomEstateMarkerView가 아닌 경우 즉시 생성
            let markerImage = createImageFromView(view: view, size: targetSize)
            
            let iconStyle = PoiIconStyle(
                symbol: markerImage,
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
            
            let emptyTextStyle = PoiTextStyle(textLineStyles: [])
            let perLevelStyle = PerLevelPoiStyle(
                iconStyle: iconStyle,
                textStyle: emptyTextStyle,
                level: 15
            )
            
            let poiStyle = PoiStyle(styleID: styleID, styles: [perLevelStyle])
            manager.addPoiStyle(poiStyle)
            
            print("✅ 마커 스타일 즉시 생성: \(styleID)")
            completion?()
        }
    }
    
    /// - UIView를 UIImage로 변환 (커스텀 메서드)
    private func createImageFromView(view: UIView, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
    
    /// - 클러스터 마커 스타일들 생성 (CustomClusterMarkerView 사용)
    func createClusterMarkerStyles(manager: LabelManager) {
        // 소규모 클러스터 (2-9개) - CustomClusterMarkerView
        let smallClusterView = CustomClusterMarkerView(count: 5)
        let smallSize = ClusterSize.fromCount(5)
        createCustomClusterStyleFromView(manager: manager, view: smallClusterView, styleID: "cluster_custom_small", size: smallSize)
        
        // 중간 클러스터 (10-49개) - CustomClusterMarkerView
        let mediumClusterView = CustomClusterMarkerView(count: 25)
        let mediumSize = ClusterSize.fromCount(25)
        createCustomClusterStyleFromView(manager: manager, view: mediumClusterView, styleID: "cluster_custom_medium", size: mediumSize)
        
        // 대규모 클러스터 (50개 이상) - CustomClusterMarkerView
        let largeClusterView = CustomClusterMarkerView(count: 100)
        let largeSize = ClusterSize.fromCount(100)
        createCustomClusterStyleFromView(manager: manager, view: largeClusterView, styleID: "cluster_custom_large", size: largeSize)
        
        print("✅ Custom cluster marker styles created with CustomClusterMarkerView")
    }
    
    /// - CustomClusterMarkerView를 사용한 클러스터 스타일 생성 (줌 레벨별 크기)
    func createCustomClusterStyleFromView(manager: LabelManager, view: CustomClusterMarkerView, styleID: String, size: ClusterSize) {
        // 여러 줌 레벨에 대해 다른 크기의 스타일 생성
        var styles: [PerLevelPoiStyle] = []
        
        // 줌 레벨별로 다른 스케일의 아이콘 생성
        let zoomLevels = [0, 3, 6, 9, 12, 14]
        
        for zoomLevel in zoomLevels {
            let scaleFactor = getClusterScaleFactor(for: zoomLevel)
            let scaledDiameter = size.diameter * scaleFactor
            let frameSize = CGSize(width: scaledDiameter + 10, height: scaledDiameter + 10)
            
            // 뷰 복사 및 스케일 적용  
            let scaledView = CustomClusterMarkerView(count: size == .small ? 5 : size == .medium ? 25 : 100)
            scaledView.frame = CGRect(origin: .zero, size: frameSize)
            scaledView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            
            // 레이아웃 강제 업데이트
            scaledView.setNeedsLayout()
            scaledView.layoutIfNeeded()
            
            // UIView를 이미지로 변환
            let clusterImage = createImageFromView(view: scaledView, size: frameSize)
            
            // 아이콘 스타일 생성
            let iconStyle = PoiIconStyle(
                symbol: clusterImage,
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
            
            // 빈 텍스트 스타일 생성
            let emptyTextStyle = PoiTextStyle(textLineStyles: [])
            
            styles.append(PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: zoomLevel))
        }
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        manager.addPoiStyle(poiStyle)
        
        print("✅ Created multi-scale cluster style '\(styleID)' for zoom levels: \(zoomLevels)")
    }
    
    /// - 개별 클러스터 스타일 생성
    func createClusterStyle(manager: LabelManager, styleID: String, size: CGFloat, color: UIColor) {
        // 원형 클러스터 이미지 생성
        let clusterImage = createClusterImage(size: size, color: color)
        
        // 아이콘 스타일
        let iconStyle = PoiIconStyle(
            symbol: clusterImage,
            anchorPoint: CGPoint(x: 0.5, y: 0.5)
        )
        
        // 클러스터 내 개수 텍스트 스타일
        let countTextStyle = PoiTextStyle(textLineStyles: [
            PoiTextLineStyle(textStyle: TextStyle(
                fontSize: UInt(size * 0.3), // 크기에 비례한 폰트
                fontColor: UIColor.white,
                strokeThickness: 0,
                strokeColor: UIColor.clear
            ))
        ])
        countTextStyle.textLayouts = [.center] // 중앙에 텍스트 배치
        
        // 레벨별 스타일 (줌 레벨 0~14에서 클러스터 표시)
        let styles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: countTextStyle, level: 0),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: countTextStyle, level: 14)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        manager.addPoiStyle(poiStyle)
    }
    
    /// - 클러스터 원형 이미지 생성
    func createClusterImage(size: CGFloat, color: UIColor) -> UIImage {
        let imageSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: imageSize)
            
            // 외곽 그림자
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
            
            // 메인 원형
            color.setFill()
            context.cgContext.fillEllipse(in: rect)
            
            // 내부 하이라이트 원
            let innerRect = rect.insetBy(dx: 2, dy: 2)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [color.withAlphaComponent(0.3).cgColor, UIColor.clear.cgColor] as CFArray,
                                    locations: [0.0, 1.0])
            
            if let gradient = gradient {
                context.cgContext.drawRadialGradient(gradient,
                                                   startCenter: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.3),
                                                   startRadius: 0,
                                                   endCenter: CGPoint(x: rect.midX, y: rect.midY),
                                                   endRadius: rect.width / 2,
                                                   options: [])
            }
            
            // 테두리
            UIColor.white.setStroke()
            context.cgContext.setLineWidth(2)
            context.cgContext.strokeEllipse(in: rect)
        }
    }
    
    /// - 개별 매물 마커 스타일 생성
    func createEstateMarkerStyle(manager: LabelManager, styleID: String, color: UIColor) {
        // 마커 이미지 생성
        let markerImage = createEstateMarkerImage(color: color)
        
        // 아이콘 스타일
        let iconStyle = PoiIconStyle(
            symbol: markerImage,
            anchorPoint: CGPoint(x: 0.5, y: 1.0)
        )
        
        // 가격 텍스트 스타일
        let priceTextStyle = PoiTextStyle(textLineStyles: [
            PoiTextLineStyle(textStyle: TextStyle(
                fontSize: 11,
                fontColor: UIColor.white,
                strokeThickness: 2,
                strokeColor: UIColor.black
            ))
        ])
        priceTextStyle.textLayouts = [.top]
        
        // 레벨별 스타일 (줌 레벨 10~14에서 기본 마커 표시)
        let styles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: priceTextStyle, level: 10),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: priceTextStyle, level: 14)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        manager.addPoiStyle(poiStyle)
    }
    
    /// - 매물 마커 이미지 생성
    func createEstateMarkerImage(color: UIColor) -> UIImage {
        // 캐시 키 생성
        let cacheKey = "marker_\(color.hexString)"
        
        // 캐시에서 이미지 확인
        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }
        
        // 캐시 크기 제한
        if imageCache.count >= maxCacheSize {
            imageCache.removeAll()
        }
        
        let size = CGSize(width: 32, height: 42)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // 드롭 핀 모양 생성
            let path = UIBezierPath()
            let radius: CGFloat = 16
            let tipHeight: CGFloat = 10
            
            // 원형 상단부
            path.addArc(withCenter: CGPoint(x: size.width/2, y: radius),
                       radius: radius,
                       startAngle: 0,
                       endAngle: .pi * 2,
                       clockwise: true)
            
            // 하단 뾰족한 부분
            path.move(to: CGPoint(x: size.width/2 - 6, y: radius * 1.5))
            path.addLine(to: CGPoint(x: size.width/2, y: size.height))
            path.addLine(to: CGPoint(x: size.width/2 + 6, y: radius * 1.5))
            
            // 마커 색상 적용
            color.setFill()
            path.fill()
            
            // 테두리
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            // 중앙 원
            let innerCircle = UIBezierPath(arcCenter: CGPoint(x: size.width/2, y: radius),
                                         radius: 6,
                                         startAngle: 0,
                                         endAngle: .pi * 2,
                                         clockwise: true)
            UIColor.white.setFill()
            innerCircle.fill()
        }
        
        // 캐시에 저장
        imageCache[cacheKey] = image
        return image
    }
    
    /// - 마커 애니메이션 설정
    func setupMarkerAnimations(manager: LabelManager) {
        // 드롭 애니메이션 효과
        let dropEffect = DropAnimationEffect(pixelHeight: 100)
        dropEffect.interpolation = AnimationInterpolation(duration: 800, method: .cubicOut)
        
        markerAnimator = manager.addPoiAnimator(animatorID: "estateMarkerAnimator", effect: dropEffect)
        
        print("✅ Marker animations setup completed")
    }
    
    /// - LOD 레이어 설정 (클러스터링)
    func setupEstateLodLayer(manager: LabelManager) {
        let lodOptions = LodLabelLayerOptions(
            layerID: "EstateMarkerLayer",
            competitionType: .none,  // 마커 겹침 허용
            competitionUnit: .poi,
            orderType: .rank,
            zOrder: 10001,
            radius: 40.0  // 클러스터링 반경
        )
        
        estateLodLayer = manager.addLodLabelLayer(option: lodOptions)
        
        if estateLodLayer != nil {
            print("✅ Estate LOD Layer setup completed")
        } else {
            print("❌ Failed to create Estate LOD Layer")
        }
    }
    
    /// - LOD를 사용한 효율적인 매물 마커 생성 (사용 중단됨)
    func createEstateMarkersWithLOD(from estates: [EstateGeoLocationDataResponse]) {
        print("⚠️ 기존 마커 생성 메서드 호출됨 - 최적화된 메서드를 사용해야 함!")
        return // 기존 메서드 사용 중단
    }
    
    /// - 최적화된 마커 생성 (커스텀 뷰 사용)
    private func createEstateMarkersOptimized(from estates: [EstateGeoLocationDataResponse]) {
        guard let lodLayer = estateLodLayer, let labelManager = labelManager else {
            print("❌ LOD Layer 또는 Label Manager가 nil")
            return
        }
        
        // 클러스터링 수행
        let clusteringResult = performClusteringOptimized(estates: estates)
        
        var poiOptions: [PoiOptions] = []
        var positions: [MapPoint] = []
        
        print("🔨 마커 생성 시작: \(clusteringResult.clusters.count)개 클러스터, \(clusteringResult.individualMarkers.count)개 개별 매물")
        
        // 1. 클러스터 마커 생성 (CustomClusterMarkerView 사용)
        for (index, cluster) in clusteringResult.clusters.enumerated() {
            let clusterStyleID = createOptimizedClusterStyle(for: cluster, index: index)
            
            let option = PoiOptions(styleID: clusterStyleID)
            option.rank = index + 100  // 각 클러스터별로 고유한 rank
            option.clickable = true
            option.transformType = .decal
            
            poiOptions.append(option)
            
            // 병합된 클러스터는 계산된 중심점에 표시
            positions.append(cluster.centerPosition)
            
            print("🔨 클러스터 마커 준비: \(cluster.count)개 매물, 위치: (\(String(format: "%.6f", cluster.centerPosition.wgsCoord.latitude)), \(String(format: "%.6f", cluster.centerPosition.wgsCoord.longitude))), 스타일ID: \(clusterStyleID)")
        }
        
        // 2. 개별 매물 마커 생성 (CustomEstateMarkerView 사용)
        for (index, estate) in clusteringResult.individualMarkers.enumerated() {

            let estateStyleID = createOptimizedEstateStyle(for: estate, index: index)
            
            let option = PoiOptions(styleID: estateStyleID)
            option.rank = index + 1000 + clusteringResult.clusters.count  // 개별 마커는 더 높은 rank
            option.clickable = true
            option.transformType = .decal
            
            poiOptions.append(option)
            positions.append(MapPoint(longitude: estate.geolocation.longitude, 
                                    latitude: estate.geolocation.latitude))
            
            print("🔨 개별 마커 준비: 매물ID \(estate.estate_id), 스타일ID: \(estateStyleID)")
        }
        
        print("🔨 총 \(poiOptions.count)개 마커를 LOD Layer에 추가 중...")
        
        // 한 번에 모든 마커 추가
        if let addedPois = lodLayer.addLodPois(options: poiOptions, at: positions) {
            print("✅ LOD Layer에 \(addedPois.count)개 마커 추가 성공")
            
            // 참조 저장
            saveMarkerReferences(pois: addedPois, clusteringResult: clusteringResult)
            
            // 즉시 표시
            lodLayer.showAllLodPois()
            print("👀 모든 마커 표시 활성화")
            
            // 개별 마커도 강제로 표시
            for poi in addedPois {
                poi.show()
            }
            print("🔄 개별 마커 \(addedPois.count)개 강제 표시")
            
            // 약간의 지연 후 다시 한 번 표시
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                lodLayer.showAllLodPois()
                print("🔄 0.2초 후 재표시 완료")
                
                // 각 POI의 표시 상태 확인
                for (index, poi) in addedPois.enumerated() {
                    print("🔍 POI \(index): 생성됨")
                }
            }
        } else {
            print("❌ LOD Layer에 마커 추가 실패")
        }
    }
    
    /// - 최적화된 클러스터 스타일 생성
    private func createOptimizedClusterStyle(for cluster: EstateCluster, index: Int) -> String {
        let styleID = "optimized_cluster_\(index)_\(cluster.count)_\(Int(cluster.centerPosition.wgsCoord.latitude * 1000000))_\(Int(cluster.centerPosition.wgsCoord.longitude * 1000000))"
        
        guard let labelManager = labelManager else { 
            print("❌ Label manager nil for cluster \(index)")
            return "cluster_custom_small" 
        }
        
        print("🎨 클러스터 스타일 생성 시작: \(styleID), 개수: \(cluster.count)")
        
        // CustomClusterMarkerView 생성
        let clusterView = CustomClusterMarkerView(count: cluster.count)
        let clusterSize = ClusterSize.fromCount(cluster.count)
        
        // 각 클러스터마다 다른 크기로 차별화
        let frameSize: CGSize
        if cluster.count == 1 {
            frameSize = CGSize(width: 45, height: 45) // 단일 매물
        } else if cluster.count <= 5 {
            frameSize = CGSize(width: 50, height: 50) // 소수 매물
        } else {
            frameSize = CGSize(width: 60, height: 60) // 다수 매물
        }
        
        // 모든 클러스터 배경색을 deepCream으로 통일
        clusterView.backgroundColor = SHColor.Brand.deepCream
        
        clusterView.frame = CGRect(origin: .zero, size: frameSize)
        clusterView.setNeedsLayout()
        clusterView.layoutIfNeeded()
        
        print("🎨 클러스터 뷰 크기: \(frameSize), 배경색 설정완료, 개수: \(cluster.count)")
        
        // UIView를 이미지로 변환
        let clusterImage = createImageFromView(view: clusterView, size: frameSize)
        print("🎨 클러스터 이미지 생성 완료: \(clusterImage.size)")
        
        // 아이콘 스타일 생성
        let iconStyle = PoiIconStyle(
            symbol: clusterImage,
            anchorPoint: CGPoint(x: 0.5, y: 0.5)
        )
        
        let emptyTextStyle = PoiTextStyle(textLineStyles: [])
        
        // 클러스터는 모든 줌 레벨에서 표시 (테스트용)
        let styles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 0),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 21)
        ]
        
        print("🎨 클러스터 스타일 줌 레벨 설정: 0-21 (모든 레벨)")
        
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        labelManager.addPoiStyle(poiStyle)
        
        print("✅ 클러스터 스타일 생성 완료: \(styleID)")
        return styleID
    }
    
    /// - 최적화된 매물 스타일 생성 (줌 레벨별 스케일 적용)
    private func createOptimizedEstateStyle(for estate: EstateGeoLocationDataResponse, index: Int) -> String {
        let styleID = "optimized_estate_\(index)_\(estate.estate_id)_zoom\(currentZoomLevel)"
        
        guard let labelManager = labelManager else { return "estate_default" }
        
        // 줌 레벨에 따른 스케일 팩터 계산
        let scaleFactor = getEstateMarkerScaleFactor(for: currentZoomLevel)
        
        // CustomEstateMarkerView 생성
        let estateView = CustomEstateMarkerView()
        estateView.configure(with: estate)
        
        // 고정 크기 (1.0x 스케일)
        let fixedSize = CGSize(width: 72, height: 100)
        
        estateView.frame = CGRect(origin: .zero, size: fixedSize)
        estateView.setNeedsLayout()
        estateView.layoutIfNeeded()
        
        print("🏠 매물 마커 생성: 매물ID \(estate.estate_id), 고정 크기: \(fixedSize)")
        
        // UIView를 이미지로 변환
        let estateImage = createImageFromView(view: estateView, size: fixedSize)
        
        // 아이콘 스타일 생성
        let iconStyle = PoiIconStyle(
            symbol: estateImage,
            anchorPoint: CGPoint(x: 0.5, y: 1.0) // 하단 중앙을 기준점으로
        )
        
        let emptyTextStyle = PoiTextStyle(textLineStyles: [])
        
        // 개별 매물 마커는 줌 레벨 11 이상에서 표시 (테스트용으로 낮춤)
        let styles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 11),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 21)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        labelManager.addPoiStyle(poiStyle)
        
        return styleID
    }
    
    /// - 마커 참조 저장 (분리된 메서드)
    private func saveMarkerReferences(pois: [LodPoi], clusteringResult: ClusteringResult) {
        print("💾 마커 참조 저장 시작: \(pois.count)개 POI, \(clusteringResult.clusters.count)개 클러스터")
        
        for (index, poi) in pois.enumerated() {
            if index < clusteringResult.clusters.count {
                // 클러스터 마커
                let cluster = clusteringResult.clusters[index]
                let clusterKey = "cluster_\(String(format: "%.6f", cluster.centerPosition.wgsCoord.latitude))_\(String(format: "%.6f", cluster.centerPosition.wgsCoord.longitude))"
                clusterMarkers[clusterKey] = poi
                clusterData[clusterKey] = cluster.estates
                poi.addPoiTappedEventHandler(target: self, handler: EstateMapManager.onClusterMarkerTapped)
                
                print("💾 클러스터 참조 저장: 인덱스 \(index), 키: \(clusterKey), 개수: \(cluster.count)")
            } else {
                // 개별 마커
                let estateIndex = index - clusteringResult.clusters.count
                if estateIndex < clusteringResult.individualMarkers.count {
                    let estate = clusteringResult.individualMarkers[estateIndex]
                    let estateId = "estate_\(estate.estate_id)"
                    currentEstateMarkers[estateId] = poi
                    poi.addPoiTappedEventHandler(target: self, handler: EstateMapManager.onEstateMarkerTapped)
                    
                    print("💾 개별 마커 참조 저장: 인덱스 \(index), 매물ID: \(estate.estate_id)")
                }
            }
        }
        
        print("💾 참조 저장 완료: 클러스터 \(clusterMarkers.count)개, 개별 마커 \(currentEstateMarkers.count)개")
    }
    
    /// - 동적 마커 스타일 생성 (각 매물마다 고유한 썸네일과 가격 표시)
    func createDynamicMarkerStyle(for estate: EstateGeoLocationDataResponse, priceText: String, index: Int) -> String {
        let styleID = "estate_dynamic_\(index)_\(estate.estate_id)"
        
        // 해당 스타일이 이미 존재하면 재사용
        guard let labelManager = labelManager else { return "estate_custom_default" }
        
        // 동적으로 커스텀 마커 뷰 생성 (실제 매물 데이터로)
        let markerView = CustomEstateMarkerView()
        markerView.configure(with: estate)
        
        // 스타일 생성 (이미지 로딩 완료 후 실행)
        createMarkerStyleFromView(manager: labelManager, view: markerView, styleID: styleID)
        
        return styleID
    }
    
    /// - 동적 클러스터 마커 스타일 생성 (줌 레벨별 스케일 적용)
    func createDynamicClusterMarkerStyle(for cluster: EstateCluster, index: Int) -> String {
        let styleID = "cluster_dynamic_\(index)_\(cluster.count)_zoom\(currentZoomLevel)"
        
        guard let labelManager = labelManager else { return "cluster_custom_small" }
        
        // 줌 레벨에 따른 스케일 팩터 계산
        let scaleFactor = getClusterScaleFactor(for: currentZoomLevel)
        
        // CustomClusterMarkerView로 동적 클러스터 마커 생성
        let clusterMarkerView = CustomClusterMarkerView(count: cluster.count)
        
        // 클러스터 크기에 줌 레벨 스케일 적용
        let baseClusterSize = ClusterSize.fromCount(cluster.count)
        let scaledDiameter = baseClusterSize.diameter * scaleFactor
        let frameSize = CGSize(width: scaledDiameter + 10, height: scaledDiameter + 10)
        
        // 스케일된 크기로 뷰 업데이트
        clusterMarkerView.frame = CGRect(origin: .zero, size: frameSize)
        clusterMarkerView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        
        // 레이아웃 강제 업데이트
        clusterMarkerView.setNeedsLayout()
        clusterMarkerView.layoutIfNeeded()
        
        // UIView를 이미지로 변환
        let clusterImage = createImageFromView(view: clusterMarkerView, size: frameSize)
        
        // 아이콘 스타일 생성
        let iconStyle = PoiIconStyle(
            symbol: clusterImage,
            anchorPoint: CGPoint(x: 0.5, y: 0.5)  // 중앙이 좌표점
        )
        
        // 빈 텍스트 스타일 생성 (클러스터 뷰에 이미 텍스트 포함)
        let emptyTextStyle = PoiTextStyle(textLineStyles: [])
        
        // 클러스터는 줌 레벨 0~14에서만 표시
        let styles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 0),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: emptyTextStyle, level: 14)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: styles)
        labelManager.addPoiStyle(poiStyle)
        
        print("✅ Created scaled cluster style '\(styleID)' with \(cluster.count) estates (scale: \(scaleFactor))")
        
        return styleID
    }
    
    /// - 줌 레벨에 따른 클러스터 스케일 팩터 계산
    func getClusterScaleFactor(for zoomLevel: Int) -> CGFloat {
        switch zoomLevel {
        case 0...5:   return 0.6    // 광역 뷰: 작은 클러스터
        case 6...7:   return 0.8    // 도시 뷰: 중간 크기
        case 8...9:   return 1.0    // 구 단위: 기본 크기
        case 10...11: return 1.2    // 동 단위: 약간 큰 크기
        case 12...14: return 1.4    // 상세 뷰: 큰 크기
        default:      return 1.0    // 기본값
        }
    }
    
    /// - 개별 매물 마커 스케일 팩터 (줌 레벨과 상관없이 1.0x 고정)
    func getEstateMarkerScaleFactor(for zoomLevel: Int) -> CGFloat {
        return 1.0
    }
    
    /// - 대중적인 클러스터링 수행 (줌 레벨 적응형)
    func performClustering(estates: [EstateGeoLocationDataResponse]) -> ClusteringResult {
        guard !estates.isEmpty else {
            return ClusteringResult(individualMarkers: [], clusters: [])
        }
        
        let zoomLevel = currentZoomLevel
        
        // 줌 레벨에 따른 클러스터링 전략 선택
        let result: ClusteringResult
        
        switch zoomLevel {
        case 0...12:  
            let gridSize = getGridSize(for: zoomLevel)
            result = performGridClustering(estates: estates, gridSize: gridSize)
        case 13...15: 
            let distance = getClusterDistance(for: zoomLevel)
            result = performDistanceClustering(estates: estates, distance: distance)
        default:      
            result = ClusteringResult(individualMarkers: estates, clusters: [])
        }
        
        return result
    }
    
    /// - 최적화된 클러스터링 (성능 우선)
    private func performClusteringOptimized(estates: [EstateGeoLocationDataResponse]) -> ClusteringResult {
        guard !estates.isEmpty else {
            return ClusteringResult(individualMarkers: [], clusters: [])
        }
        
        let zoomLevel = currentZoomLevel
        print("🔍 클러스터링 시작: \(estates.count)개 매물, 줌 \(zoomLevel)")
        
        let result: ClusteringResult
        let isShowingIndividualMarkers: Bool
        
        switch zoomLevel {
        case 0...12:   
            result = performAggressiveGridClustering(estates: estates, gridSize: getGridSize(for: zoomLevel))
            isShowingIndividualMarkers = false
        default:      
            result = ClusteringResult(individualMarkers: estates, clusters: [])
            isShowingIndividualMarkers = true
        }
        
        // 개별 마커 표시 상태 변경을 delegate에 알림
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.individualMarkersDisplayStateChanged(isDisplaying: isShowingIndividualMarkers)
        }
        
        // 겹치는 클러스터 병합 (다단계)
        let mergeDistance = getClusterMergeDistance(for: zoomLevel)
        print("🔗 병합 거리 설정: \(mergeDistance)m (줌 레벨: \(zoomLevel))")
        
        var mergedResult = mergeOverlappingClusters(result: result, mergeDistance: mergeDistance)
        
        // 다단계 병합: 병합된 클러스터들을 다시 한번 병합 체크
        var previousCount = mergedResult.clusters.count
        var iterationCount = 1
        
        while iterationCount <= 3 { // 최대 3번 반복
            let secondMergedResult = mergeOverlappingClusters(result: mergedResult, mergeDistance: mergeDistance)
            
            if secondMergedResult.clusters.count < previousCount {
                print("🔗 \(iterationCount + 1)차 병합: \(previousCount)개 → \(secondMergedResult.clusters.count)개 클러스터")
                mergedResult = secondMergedResult
                previousCount = secondMergedResult.clusters.count
                iterationCount += 1
            } else {
                print("🔗 더 이상 병합할 클러스터 없음 - 병합 완료")
                break
            }
        }
        
        // 결과 검증
        let originalClusters = result.clusters.count
        let finalClusters = mergedResult.clusters.count
        let totalInClusters = mergedResult.clusters.reduce(0) { $0 + $1.count }
        let totalProcessed = totalInClusters + mergedResult.individualMarkers.count
        
        print("🔍 최종 클러스터링 결과:")
        print("   📊 병합 전후: \(originalClusters)개 → \(finalClusters)개 클러스터")
        print("   📊 매물 분포: 클러스터 \(finalClusters)개(\(totalInClusters)개 매물) + 개별 \(mergedResult.individualMarkers.count)개")
        print("   📊 총합: \(totalProcessed)개 (원본: \(estates.count)개)")
        
        if totalProcessed != estates.count {
            print("⚠️ 매물 개수 불일치! 원본: \(estates.count), 처리됨: \(totalProcessed)")
        } else {
            print("✅ 매물 개수 검증 완료!")
        }
        
        return mergedResult
    }
    
    /// - 간단한 Grid 클러스터링 (성능 최적화)
    private func performSimpleGridClustering(estates: [EstateGeoLocationDataResponse], gridSize: Double) -> ClusteringResult {
        var gridMap: [String: [EstateGeoLocationDataResponse]] = [:]
        
        // 빠른 그룹핑
        for estate in estates {
            let gridX = Int(estate.geolocation.longitude / gridSize)
            let gridY = Int(estate.geolocation.latitude / gridSize)
            let gridKey = "\(gridX)_\(gridY)"
            
            if gridMap[gridKey] == nil {
                gridMap[gridKey] = []
            }
            gridMap[gridKey]?.append(estate)
        }
        
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        
        // 빠른 클러스터 생성
        for (_, gridEstates) in gridMap {
            if gridEstates.count >= 2 {
                let centerLat = gridEstates.map { $0.geolocation.latitude }.reduce(0, +) / Double(gridEstates.count)
                let centerLon = gridEstates.map { $0.geolocation.longitude }.reduce(0, +) / Double(gridEstates.count)
                
                clusters.append(EstateCluster(
                    estates: gridEstates,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                ))
            } else if let singleEstate = gridEstates.first {
                individualMarkers.append(singleEstate)
            }
        }
        
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - 간단한 Distance 클러스터링 (성능 최적화)
    private func performSimpleDistanceClustering(estates: [EstateGeoLocationDataResponse], distance: Double) -> ClusteringResult {
        var visited: Set<Int> = []
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        
        for (index, estate) in estates.enumerated() {
            if visited.contains(index) { continue }
            
            var cluster: [EstateGeoLocationDataResponse] = [estate]
            visited.insert(index)
            
            // 간단한 근접 탐색 (첫 번째 단계만)
            for (neighborIndex, neighborEstate) in estates.enumerated() {
                if visited.contains(neighborIndex) { continue }
                
                let dist = calculateSimpleDistance(
                    lat1: estate.geolocation.latitude,
                    lon1: estate.geolocation.longitude,
                    lat2: neighborEstate.geolocation.latitude,
                    lon2: neighborEstate.geolocation.longitude
                )
                
                if dist <= distance {
                    cluster.append(neighborEstate)
                    visited.insert(neighborIndex)
                }
            }
            
            // 클러스터 생성
            if cluster.count >= 2 {
                let centerLat = cluster.map { $0.geolocation.latitude }.reduce(0, +) / Double(cluster.count)
                let centerLon = cluster.map { $0.geolocation.longitude }.reduce(0, +) / Double(cluster.count)
                
                clusters.append(EstateCluster(
                    estates: cluster,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                ))
            } else if let singleEstate = cluster.first {
                individualMarkers.append(singleEstate)
            }
        }
        
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - 간단한 거리 계산 (성능 우선)
    private func calculateSimpleDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        // 유클리드 거리 근사 (빠른 계산)
        let latDiff = lat1 - lat2
        let lonDiff = lon1 - lon2
        return sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111000 // 대략적인 미터 변환
    }
    
    /// - 강력한 Grid 클러스터링 (낮은 줌 레벨용)
    private func performAggressiveGridClustering(estates: [EstateGeoLocationDataResponse], gridSize: Double) -> ClusteringResult {
        var gridMap: [String: [EstateGeoLocationDataResponse]] = [:]
        
        // 모든 매물을 그리드에 할당
        for estate in estates {
            let gridX = Int(estate.geolocation.longitude / gridSize)
            let gridY = Int(estate.geolocation.latitude / gridSize)
            let gridKey = "\(gridX)_\(gridY)"
            
            if gridMap[gridKey] == nil {
                gridMap[gridKey] = []
            }
            gridMap[gridKey]?.append(estate)
        }
        
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        
        // 강력한 클러스터링: 1개 매물도 클러스터로 만들기 (낮은 줌에서는)
        for (_, gridEstates) in gridMap {
            if gridEstates.count >= 1 { // 1개부터 클러스터링
                let centerLat = gridEstates.map { $0.geolocation.latitude }.reduce(0, +) / Double(gridEstates.count)
                let centerLon = gridEstates.map { $0.geolocation.longitude }.reduce(0, +) / Double(gridEstates.count)
                
                clusters.append(EstateCluster(
                    estates: gridEstates,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                ))
            }
        }
        
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - 균형잡힌 Distance 클러스터링 (중간 줌 레벨용)
    private func performBalancedDistanceClustering(estates: [EstateGeoLocationDataResponse], distance: Double) -> ClusteringResult {
        var visited: Set<Int> = []
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        
        print("🎯 Distance 클러스터링 시작: 거리 임계값 \(distance)m")
        
        for (index, estate) in estates.enumerated() {
            if visited.contains(index) { continue }
            
            var cluster: [EstateGeoLocationDataResponse] = [estate]
            visited.insert(index)
            
            // 근처 매물 찾기
            var nearbyCount = 0
            for (neighborIndex, neighborEstate) in estates.enumerated() {
                if visited.contains(neighborIndex) { continue }
                
                let dist = calculateSimpleDistance(
                    lat1: estate.geolocation.latitude,
                    lon1: estate.geolocation.longitude,
                    lat2: neighborEstate.geolocation.latitude,
                    lon2: neighborEstate.geolocation.longitude
                )
                
                if dist <= distance {
                    cluster.append(neighborEstate)
                    visited.insert(neighborIndex)
                    nearbyCount += 1
                }
            }
            
            // 2개 이상이면 클러스터, 1개면 개별 마커
            if cluster.count >= 2 {
                let centerLat = cluster.map { $0.geolocation.latitude }.reduce(0, +) / Double(cluster.count)
                let centerLon = cluster.map { $0.geolocation.longitude }.reduce(0, +) / Double(cluster.count)
                
                clusters.append(EstateCluster(
                    estates: cluster,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                ))
                print("📍 클러스터 생성: \(cluster.count)개 매물 (인덱스 \(index) 기준으로 \(nearbyCount)개 근처 매물 발견)")
            } else if let singleEstate = cluster.first {
                individualMarkers.append(singleEstate)
                print("🏠 개별 매물: 인덱스 \(index) (근처 매물 없음)")
            }
        }
        
        print("🎯 Distance 클러스터링 완료: \(clusters.count)개 클러스터, \(individualMarkers.count)개 개별 매물")
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - Grid 기반 클러스터링 (광역 뷰용 - Google Maps 스타일)
    func performGridClustering(estates: [EstateGeoLocationDataResponse], gridSize: Double) -> ClusteringResult {
        print("🟦 ===== GRID CLUSTERING START =====")
        print("🟦 Grid size: \(gridSize) degrees")
        
        var gridMap: [String: [EstateGeoLocationDataResponse]] = [:]
        
        // 각 매물을 그리드 셀에 할당
        for (index, estate) in estates.enumerated() {
            let gridX = Int(estate.geolocation.longitude / gridSize)
            let gridY = Int(estate.geolocation.latitude / gridSize)
            let gridKey = "\(gridX)_\(gridY)"
            
            if gridMap[gridKey] == nil {
                gridMap[gridKey] = []
                print("🟦 Created new grid cell: \(gridKey)")
            }
            gridMap[gridKey]?.append(estate)
            
            if index < 3 { // 처음 3개만 로그
                print("🟦 Estate \(index + 1) assigned to grid \(gridKey): (\(String(format: "%.4f", estate.geolocation.latitude)), \(String(format: "%.4f", estate.geolocation.longitude)))")
            }
        }
        
        print("🟦 Total grid cells created: \(gridMap.count)")
        
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        
        // 그리드 셀별로 클러스터 생성
        for (gridKey, gridEstates) in gridMap {
            print("🟦 Processing grid \(gridKey) with \(gridEstates.count) estates")
            
            if gridEstates.count >= 2 {
                let centerLat = gridEstates.map { $0.geolocation.latitude }.reduce(0, +) / Double(gridEstates.count)
                let centerLon = gridEstates.map { $0.geolocation.longitude }.reduce(0, +) / Double(gridEstates.count)
                
                let cluster = EstateCluster(
                    estates: gridEstates,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                )
                clusters.append(cluster)
                print("📍 Created cluster with \(gridEstates.count) estates at (\(String(format: "%.4f", centerLat)), \(String(format: "%.4f", centerLon)))")
            } else if let singleEstate = gridEstates.first {
                individualMarkers.append(singleEstate)
                print("🏠 Single estate kept as individual marker: (\(String(format: "%.4f", singleEstate.geolocation.latitude)), \(String(format: "%.4f", singleEstate.geolocation.longitude)))")
            }
        }
        
        print("🟦 ===== GRID CLUSTERING END =====")
        print("🏠 Grid result: \(clusters.count) clusters, \(individualMarkers.count) individual markers")
        
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - Distance 기반 클러스터링 (DBSCAN 비슷한 알고리즘)
    func performDistanceClustering(estates: [EstateGeoLocationDataResponse], distance: Double) -> ClusteringResult {
        print("📍 ===== DISTANCE CLUSTERING START =====")
        print("📍 Distance threshold: \(distance)m")
        
        var visited: Set<Int> = []
        var clusters: [EstateCluster] = []
        var individualMarkers: [EstateGeoLocationDataResponse] = []
        var clusterCount = 0
        
        for (index, estate) in estates.enumerated() {
            if visited.contains(index) { continue }
            
            print("📍 Starting new cluster search from estate \(index + 1): (\(String(format: "%.4f", estate.geolocation.latitude)), \(String(format: "%.4f", estate.geolocation.longitude)))")
            
            var cluster: [EstateGeoLocationDataResponse] = []
            var toVisit: [Int] = [index]
            var neighborsFound = 0
            
            while !toVisit.isEmpty {
                let currentIndex = toVisit.removeFirst()
                if visited.contains(currentIndex) { continue }
                
                visited.insert(currentIndex)
                let currentEstate = estates[currentIndex]
                cluster.append(currentEstate)
                
                print("📍   Added estate \(currentIndex + 1) to current cluster")
                
                // 인근 매물 찾기
                for (neighborIndex, neighborEstate) in estates.enumerated() {
                    if visited.contains(neighborIndex) { continue }
                    
                    let dist = calculateHaversineDistance(
                        lat1: currentEstate.geolocation.latitude,
                        lon1: currentEstate.geolocation.longitude,
                        lat2: neighborEstate.geolocation.latitude,
                        lon2: neighborEstate.geolocation.longitude
                    )
                    
                    if dist <= distance {
                        toVisit.append(neighborIndex)
                        neighborsFound += 1
                        print("📍   Found neighbor: estate \(neighborIndex + 1) at \(String(format: "%.1f", dist))m distance")
                    }
                }
            }
            
            // 클러스터 생성 여부 결정
            if cluster.count >= 2 {
                clusterCount += 1
                let centerLat = cluster.map { $0.geolocation.latitude }.reduce(0, +) / Double(cluster.count)
                let centerLon = cluster.map { $0.geolocation.longitude }.reduce(0, +) / Double(cluster.count)
                
                let estateCluster = EstateCluster(
                    estates: cluster,
                    centerPosition: MapPoint(longitude: centerLon, latitude: centerLat)
                )
                clusters.append(estateCluster)
                print("📍 ✅ Created cluster #\(clusterCount) with \(cluster.count) estates at (\(String(format: "%.4f", centerLat)), \(String(format: "%.4f", centerLon)))")
            } else if let singleEstate = cluster.first {
                individualMarkers.append(singleEstate)
                print("📍 🏠 Single estate kept as individual marker: (\(String(format: "%.4f", singleEstate.geolocation.latitude)), \(String(format: "%.4f", singleEstate.geolocation.longitude)))")
            }
        }
        
        print("📍 ===== DISTANCE CLUSTERING END =====")
        print("📍 Distance result: \(clusters.count) clusters, \(individualMarkers.count) individual markers")
        
        return ClusteringResult(individualMarkers: individualMarkers, clusters: clusters)
    }
    
    /// - 줌 레벨에 따른 그리드 크기 결정 (서울시 최적화)
    func getGridSize(for zoomLevel: Int) -> Double {
        switch zoomLevel {
        case 0...5:   return 0.1     // 광역시/도 단위 (10km 격자)
        case 6...7:   return 0.05    // 서울시 전체 (5km 격자)
        case 8...9:   return 0.02    // 구 단위 (2km 격자)
        case 10...11: return 0.01    // 동 단위 (1km 격자)
        default:      return 0.005   // 상세 단위 (500m 격자)
        }
    }
    
    /// - 줌 레벨에 따른 클러스터 거리 결정 (서울시 최적화)
    func getClusterDistance(for zoomLevel: Int) -> Double {
        let distance: Double
        switch zoomLevel {
        case 10...11: distance = 2000    // 2km (광역 구 단위)
        case 12...13: distance = 1000    // 1km (구 단위)
        case 14:      distance = 500     // 500m (동 단위)
        case 15...16: distance = 250     // 250m (상세)
        default:      distance = 100     // 100m (최대 상세)
        }
        print("📏 줌 레벨 \(zoomLevel)에 대한 클러스터 거리: \(distance)m")
        return distance
    }
    
    /// - 줌 레벨에 따른 클러스터 병합 거리 결정
    func getClusterMergeDistance(for zoomLevel: Int) -> Double {
        switch zoomLevel {
        case 0...8:   return 3000   // 3km - 광역 뷰에서는 가까운 클러스터 적극 병합
        case 9...11:  return 2500   // 2.5km - 구 단위에서는 적극적 병합
        case 12...13: return 1500   // 1.5km - 동 단위에서는 중간 정도 병합
        case 14...15: return 800    // 800m - 상세 뷰에서는 보수적 병합
        default:      return 300    // 300m - 최대 상세에서는 최소한만 병합
        }
    }
    
    /// - 겹치는 클러스터 병합
    private func mergeOverlappingClusters(result: ClusteringResult, mergeDistance: Double) -> ClusteringResult {
        guard result.clusters.count > 1 else { 
            print("🔗 클러스터 병합 스킵: 클러스터가 \(result.clusters.count)개뿐")
            return result 
        }
        
        print("🔗 클러스터 병합 시작: \(result.clusters.count)개 클러스터, 병합거리: \(mergeDistance)m")
        
        // 모든 클러스터 위치 출력
        for (index, cluster) in result.clusters.enumerated() {
            print("🔗   클러스터 \(index): (\(String(format: "%.6f", cluster.centerPosition.wgsCoord.latitude)), \(String(format: "%.6f", cluster.centerPosition.wgsCoord.longitude))) - \(cluster.count)개 매물")
        }
        
        var mergedClusters: [EstateCluster] = []
        var processedIndices: Set<Int> = []
        
        for (index, cluster) in result.clusters.enumerated() {
            if processedIndices.contains(index) { continue }
            
            print("🔗 클러스터 \(index) 기준으로 병합 대상 검색 중...")
            
            // 현재 클러스터를 기준으로 병합할 클러스터들 찾기
            var mergeCandidates: [EstateCluster] = [cluster]
            processedIndices.insert(index)
            
            for (otherIndex, otherCluster) in result.clusters.enumerated() {
                if processedIndices.contains(otherIndex) { continue }
                
                let distance = calculateHaversineDistance(
                    lat1: cluster.centerPosition.wgsCoord.latitude,
                    lon1: cluster.centerPosition.wgsCoord.longitude,
                    lat2: otherCluster.centerPosition.wgsCoord.latitude,
                    lon2: otherCluster.centerPosition.wgsCoord.longitude
                )
                
                print("🔗   클러스터 \(index) ↔ \(otherIndex) 거리: \(String(format: "%.1f", distance))m (병합기준: \(mergeDistance)m)")
                
                if distance <= mergeDistance {
                    mergeCandidates.append(otherCluster)
                    processedIndices.insert(otherIndex)
                    print("🔗 ✅ 클러스터 \(index)와 \(otherIndex) 병합 결정 (거리: \(String(format: "%.1f", distance))m)")
                } else {
                    print("🔗 ❌ 클러스터 \(index)와 \(otherIndex) 병합 안함 (거리 초과)")
                }
            }
            
            // 병합된 클러스터 생성
            let mergedCluster = createMergedCluster(from: mergeCandidates)
            mergedClusters.append(mergedCluster)
            print("🔗 클러스터 그룹 \(index) 병합 완료: \(mergeCandidates.count)개 클러스터 → 1개 (총 \(mergedCluster.count)개 매물)")
        }
        
        print("🔗 클러스터 병합 최종 완료: \(result.clusters.count)개 → \(mergedClusters.count)개")
        
        return ClusteringResult(individualMarkers: result.individualMarkers, clusters: mergedClusters)
    }
    
    /// - 여러 클러스터를 하나로 병합
    private func createMergedCluster(from clusters: [EstateCluster]) -> EstateCluster {
        guard !clusters.isEmpty else {
            fatalError("Cannot merge empty cluster array")
        }
        
        if clusters.count == 1 {
            return clusters[0]
        }
        
        // 모든 매물 합치기
        var allEstates: [EstateGeoLocationDataResponse] = []
        for cluster in clusters {
            allEstates.append(contentsOf: cluster.estates)
        }
        
        // 새로운 중심점 계산 (가중평균)
        var totalLat = 0.0
        var totalLon = 0.0
        var totalCount = 0
        
        for cluster in clusters {
            let weight = cluster.count
            totalLat += cluster.centerPosition.wgsCoord.latitude * Double(weight)
            totalLon += cluster.centerPosition.wgsCoord.longitude * Double(weight)
            totalCount += weight
        }
        
        let newCenterLat = totalLat / Double(totalCount)
        let newCenterLon = totalLon / Double(totalCount)
        
        print("🔗 병합된 클러스터: \(clusters.count)개 클러스터 → \(allEstates.count)개 매물, 중심점: (\(String(format: "%.6f", newCenterLat)), \(String(format: "%.6f", newCenterLon)))")
        
        return EstateCluster(
            estates: allEstates,
            centerPosition: MapPoint(longitude: newCenterLon, latitude: newCenterLat)
        )
    }
    
    /// - 두 지점 간 실제 거리 계산 (Haversine 공식 - 미터 단위)
    func calculateHaversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0 // 지구 반지름 (미터)
        
        let lat1Rad = lat1 * .pi / 180
        let lat2Rad = lat2 * .pi / 180
        let deltaLatRad = (lat2 - lat1) * .pi / 180
        let deltaLonRad = (lon2 - lon1) * .pi / 180
        
        let a = sin(deltaLatRad/2) * sin(deltaLatRad/2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad/2) * sin(deltaLonRad/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    /// - 클러스터 크기에 따른 스타일 결정 (커스텀 UIView 우선 사용)
    func determineClusterStyle(count: Int) -> String {
        switch count {
        case 2...9:
            return "cluster_custom_small"
        case 10...49:
            return "cluster_custom_medium"
        default:
            return "cluster_custom_large"
        }
    }
    
    /// - 클러스터 마커 탭 이벤트 핸들러
    func onClusterMarkerTapped(_ param: PoiInteractionEventParam) {
        print("📍 Cluster marker tapped")
        
        // 클러스터 위치는 클러스터 생성 시 저장된 키로 찾아야 함
        if let lodPoi = param.poiItem as? LodPoi {
            // 클러스터 마커에서 해당 키 찾기
            for (clusterKey, storedPoi) in clusterMarkers {
                if storedPoi === lodPoi {
                    if let estates = clusterData[clusterKey] {
                        // 클러스터 키에서 위치 정보 추출
                        let components = clusterKey.replacingOccurrences(of: "cluster_", with: "").components(separatedBy: "_")
                        if components.count == 2,
                           let lat = Double(components[0]),
                           let lon = Double(components[1]) {
                            let position = MapPoint(longitude: lon, latitude: lat)
                            delegate?.markerClusterTapped(markerCount: estates.count, centerPosition: position, estates: estates)
                        }
                    }
                    break
                }
            }
        }
    }
    
    /// - 매물 마커 탭 이벤트 핸들러
    func onEstateMarkerTapped(_ param: PoiInteractionEventParam) {
        print("🏠 Estate marker tapped")
        
        // 매물 상세 정보 표시 로직
        // delegate?.estateMarkerTapped(estateId: ...)
        
        // 간단한 시각적 피드백
        param.poiItem.hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            param.poiItem.show()
        }
    }
    
    /// - 매물 타입에 따른 마커 스타일 결정 (커스텀 UIView 우선 사용)
    func determineMarkerStyle(for estate: EstateGeoLocationDataResponse) -> String {
        // 인기 매물 조건 (예: 조회수가 높거나 특별한 조건)
        if estate.title.contains("인기") || estate.title.contains("HOT") {
            return "estate_custom_hot"
        }
        
        // 신규 매물 조건
        if estate.title.contains("신규") || estate.title.contains("NEW") {
            return "estate_custom_new"
        }
        
        // 프리미엄 매물 조건 (가격이 높거나 특별한 조건)
        if estate.deposit >= 50000000 { // 5억 이상
            return "estate_custom_premium"
        }
        
        return "estate_custom_default"
    }
    
    /// - 매물 가격 포맷팅 (개선된 버전)
    func formatEstatePrice(deposit: Int, monthlyRent: Int) -> String {
        let depositText: String
        
        // 보증금 포맷팅
        if deposit >= 100000000 {  // 1억 이상
            depositText = "\(deposit/100000000)억"
        } else if deposit >= 10000 {  // 1만 이상
            depositText = "\(deposit/10000)만"
        } else {
            depositText = "\(deposit)"
        }
        
        // 월세 포맷팅
        if monthlyRent > 0 {
            let monthlyText = monthlyRent >= 10000 ? "\(monthlyRent/10000)만" : "\(monthlyRent)"
            return "\(depositText)/\(monthlyText)"
        } else {
            return depositText
        }
    }
    
    /// - 특정 매물 마커 업데이트
    func updateEstateMarker(estateId: String, estate: EstateGeoLocationDataResponse) {
        guard let poi = currentEstateMarkers["estate_\(estateId)"] else {
            print("❌ Estate marker not found: \(estateId)")
            return
        }
        
        // 가격 텍스트 업데이트
        let newPriceText = formatEstatePrice(deposit: estate.deposit, monthlyRent: estate.monthly_rent)
        
        // POI 텍스트 업데이트 로직 (필요시 구현)
        print("🔄 Updated estate marker \(estateId) with price: \(newPriceText)")
    }
    
    /// - 매물 마커 숨기기/보이기
    func toggleEstateMarker(estateId: String, isVisible: Bool) {
        guard let poi = currentEstateMarkers["estate_\(estateId)"] else { return }
        
        if isVisible {
            poi.show()
        } else {
            poi.hide()
        }
    }
    
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
    
    
    /// - 줌 레벨별 최대 매물 개수 제한 (성능 및 안정성을 위해)
    private func getMaxEstatesForZoomLevel(_ zoomLevel: Int) -> Int {
        switch zoomLevel {
        case 0...10:  return 50    // 낮은 줌 레벨에서는 적은 수의 매물만
        case 11...12: return 100   // 중간 줌 레벨
        case 13...15: return 200   // 높은 줌 레벨
        case 16...18: return 300   // 매우 높은 줌 레벨
        default:      return 400   // 최대 줌 레벨
        }
    }
}

/// - 클러스터링 전략 열거형
enum ClusteringStrategy {
    case grid       // Grid 기반 (광역 뷰)
    case distance   // Distance 기반 (DBSCAN 비슷)
    case none       // 클러스터링 비활성화
}

// MARK: - 클러스터링 데이터 구조
struct EstateCluster {
    let estates: [EstateGeoLocationDataResponse]
    let centerPosition: MapPoint
    
    var count: Int {
        return estates.count
    }
    
    var averagePrice: Double {
        let totalDeposit = estates.map { Double($0.deposit) }.reduce(0, +)
        return totalDeposit / Double(estates.count)
    }
}

struct ClusteringResult {
    let individualMarkers: [EstateGeoLocationDataResponse]
    let clusters: [EstateCluster]
    
    var totalMarkerCount: Int {
        return individualMarkers.count + clusters.reduce(0) { $0 + $1.count }
    }
}

// MARK: - EstateMapManagerDelegate
protocol EstateMapManagerDelegate: AnyObject {
    /// - 맵 설정이 완료되었을 때 호출
    func mapDidFinishSetup()
    
    /// - 맵 설정이 실패했을 때 호출
    func mapDidFailSetup(error: String)
    
    /// - 맵 위치가 변경되었을 때 호출
    func mapPositionChanged(latitude: Double, longitude: Double, maxDistance: Int)
    
    /// - 매물 마커가 탭되었을 때 호출
    func estateMarkerTapped(estateId: String)
    
    /// - 마커 클러스터가 탭되었을 때 호출
    func markerClusterTapped(markerCount: Int, centerPosition: MapPoint, estates: [EstateGeoLocationDataResponse])
    
    /// - 개별 마커 표시 상태가 변경되었을 때 호출
    func individualMarkersDisplayStateChanged(isDisplaying: Bool)
}

// MARK: - UIView Extension
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// MARK: - UIColor Extension
extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "%02X%02X%02X", 
                     Int(red * 255), 
                     Int(green * 255), 
                     Int(blue * 255))
    }
}
