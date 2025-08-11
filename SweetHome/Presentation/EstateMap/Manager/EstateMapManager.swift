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
        mapController?.pauseEngine()
        mapController?.resetEngine()
        removeObservers()
    }
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
        
        /// - 델리게이트에게 맵 준비 완료 알림
        delegate?.mapDidFinishSetup()
    }
    
    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("❌ Map view failed to add: \(viewName)")
        delegate?.mapDidFailSetup(error: "Failed to add map view: \(viewName)")
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