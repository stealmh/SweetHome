//
//  EstateMapViewController.swift  
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
import KakaoMapsSDK
import SnapKit

class EstateMapViewController: BaseViewController, MapControllerDelegate {
    var mapContainer: KMViewContainer?
    var mapController: KMController?
    var _observerAdded: Bool
    var _auth: Bool
    var _appear: Bool
    
    private let mapNavigationBar = EstateMapNavigationBar()
    private let mapSearchView = EsstateMapSearchView()
    private let areaFilterButton = EstateMapFilterButton()
    private let priceMonthFilterButton = EstateMapFilterButton()
    private let priceFilterButton = EstateMapFilterButton()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        _observerAdded = false
        _auth = false
        _appear = false
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        _observerAdded = false
        _auth = false
        _appear = false
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationAction()
        setupMapContainer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
        _appear = true
        if mapController?.isEnginePrepared == false {
            mapController?.prepareEngine()
        }
        
        if mapController?.isEngineActive == false {
            mapController?.activateEngine()
        }
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _appear = false
        mapController?.pauseEngine()  //렌더링 중지.
    }

    override func viewDidDisappear(_ animated: Bool) {
        removeObservers()
        mapController?.resetEngine()     //엔진 정지. 추가되었던 ViewBase들이 삭제된다.
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubviews(mapSearchView, mapNavigationBar, areaFilterButton, priceMonthFilterButton, priceFilterButton)
    }
    
    override func setupConstraints() {
        mapNavigationBar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
        
        mapSearchView.snp.makeConstraints {
            $0.top.equalTo(mapNavigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }
        
//        areaFilterButton.snp.makeConstraints {
//            $0.top.equalTo(mapSearchView.snp.bottom).offset(8)
//            $0.leading.equalToSuperview().offset(20)
//        }
//        
//        areaFilterButton.configure(title: "평수 선택")
    }
    
    deinit {
        mapController?.pauseEngine()
        mapController?.resetEngine()
    }
}
//MARK: - Navigation Bar
private extension EstateMapViewController {
    
    func setNavigationAction() {
        mapNavigationBar.backButtonTapped = {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

//MARK: - Map
extension EstateMapViewController {
    private func setupMapContainer() {
        // KMViewContainer 직접 생성
        mapContainer = KMViewContainer()
        mapContainer?.backgroundColor = .clear
        
        // 기존 view에 추가
        if let container = mapContainer {
            view.addSubview(container)
            container.snp.makeConstraints {
                $0.top.equalTo(mapSearchView.snp.bottom)
                $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            
            // 필터 버튼들을 mapContainer 위로 다시 가져오기
            view.bringSubviewToFront(areaFilterButton)
            view.bringSubviewToFront(priceMonthFilterButton)
            view.bringSubviewToFront(priceFilterButton)
            
            areaFilterButton.snp.makeConstraints {
                $0.top.equalTo(container).offset(8)
                $0.leading.equalTo(container).offset(20)
            }
            
            priceMonthFilterButton.snp.makeConstraints {
                $0.top.equalTo(areaFilterButton)
                $0.leading.equalTo(areaFilterButton.snp.trailing).offset(4)
            }
            
            priceFilterButton.snp.makeConstraints {
                $0.top.equalTo(areaFilterButton)
                $0.leading.equalTo(priceMonthFilterButton.snp.trailing).offset(4)
            }
        }
        
        guard let container = mapContainer else { return }
        mapController = KMController(viewContainer: container)
        mapController?.delegate = self
        mapController?.prepareEngine()
        
        /// - 맵 뷰 추가 (이후 addViewSucceeded에서 추가 작업 수행)
        addViews()
    }

    func authenticationSucceeded() {
        print("🔐 authenticationSucceeded called")
        
        // 일반적으로 내부적으로 인증과정 진행하여 성공한 경우 별도의 작업은 필요하지 않으나,
        // 네트워크 실패와 같은 이슈로 인증실패하여 인증을 재시도한 경우, 성공한 후 정지된 엔진을 다시 시작할 수 있다.
        if _auth == false {
            _auth = true
            print("🔐 Auth status changed to true")
        }
        
        if _appear && mapController?.isEngineActive == false {
            mapController?.activateEngine()
            print("🔐 Engine activated")
        }
        
        // 인증 성공 후 뷰 추가 (이미 추가되지 않은 경우)
        addViews()
    }
    
    func addViews() {
        print("🗺️ addViews() called")
        //여기에서 그릴 View(KakaoMap, Roadview)들을 추가한다.
        let defaultPosition: MapPoint = MapPoint(longitude: 127.108678, latitude: 37.402001)
        //지도(KakaoMap)를 그리기 위한 viewInfo를 생성
        let mapviewInfo: MapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition, defaultLevel: 7)
        
        //KakaoMap 추가.
        mapController?.addView(mapviewInfo)
    }
    
    //addView 성공 이벤트 delegate. 추가적으로 수행할 작업을 진행한다.
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        print("✅ addViewSucceeded called for \(viewName)")
        
        guard let mapView = mapController?.getView("mapview") as? KakaoMap,
              let container = mapContainer else {
            print("❌ Error: mapView or mapContainer is nil")
            return
        }
        
        mapView.viewRect = container.bounds    //뷰 add 도중에 resize 이벤트가 발생한 경우 이벤트를 받지 못했을 수 있음. 원하는 뷰 사이즈로 재조정.
        
        /// - 맵 컨테이너가 준비된 후 추가 작업 수행
        print("🎯 Setting up map overlay views")
        setupFilterButtons()
    }
    
    /// - 필터 버튼들을 설정한다
    private func setupFilterButtons() {
        /// - 필터 버튼 텍스트 설정
        areaFilterButton.configure(title: "평수 선택")
        priceMonthFilterButton.configure(title: "월세 선택")
        priceFilterButton.configure(title: "보증금 선택")
        
        print("📱 Filter buttons configured")
        
        /// - 필터 버튼 이벤트 설정
        // TODO: 필터 버튼 액션 구현
    }
    
    //addView 실패 이벤트 delegate. 실패에 대한 오류 처리를 진행한다.
    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("Failed")
    }
    
    //Container 뷰가 리사이즈 되었을때 호출된다. 변경된 크기에 맞게 ViewBase들의 크기를 조절할 필요가 있는 경우 여기에서 수행한다.
//    func containerDidResized(_ size: CGSize) {
//        let mapView: KakaoMap? = mapController?.getView("mapview") as? KakaoMap
//        mapView?.viewRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)   //지도뷰의 크기를 리사이즈된 크기로 지정한다.
//    }
       
    func addObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    
        _observerAdded = true
    }
     
    func removeObservers(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

        _observerAdded = false
    }

    @objc func willResignActive(){
        mapController?.pauseEngine()  //뷰가 inactive 상태로 전환되는 경우 렌더링 중인 경우 렌더링을 중단.
    }

    @objc func didBecomeActive(){
        mapController?.activateEngine() //뷰가 active 상태가 되면 렌더링 시작. 엔진은 미리 시작된 상태여야 함.
    }
}
