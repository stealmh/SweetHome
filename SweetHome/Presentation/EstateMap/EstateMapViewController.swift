//
//  EstateMapViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
import RxSwift
import RxCocoa
import KakaoMapsSDK
import SnapKit

class EstateMapViewController: BaseViewController {
    
    // MARK: - Properties
    /// - Navigation Bar
    private let mapNavigationBar = EstateMapNavigationBar()
    /// - Search
    private let mapSearchView = EsstateMapSearchView()
    
    /// - 매니저들
    private let mapManager = EstateMapManager()
    private let filterManager = EstateMapFilterManager()
    private let bottomCollectionManager = EstateMapBottomCollectionManager()
    
    /// - ViewModel
    private let viewModel = EstateMapViewModel()
    
    /// - RxSwift
    private let mapPositionChangedRelay = PublishSubject<(latitude: Double, longitude: Double, maxDistance: Int)>()
    private let estateTypeChangedRelay = PublishSubject<BannerEstateType>()
    private let estateSelectedRelay = PublishSubject<EstateGeoLocationDataResponse>()
    private let floatButtonTappedRelay = PublishSubject<Void>()
    private let filterChangedRelay = PublishSubject<(area: (Float, Float)?, priceMonth: (Float, Float)?, price: (Float, Float)?)>()
    
    /// - Collection View
    private var bottomCollectionView: UICollectionView!
    private var isShowingIndividualMarkers: Bool = false
    /// - float button
    private let floatButton = EstateMapFloatButton()
    
    /// - Estate Type
    var estateType: BannerEstateType? {
        didSet { 
            guard let type = estateType else { return }
            viewModel.updateEstateType(type)
            estateTypeChangedRelay.onNext(type)
        }
    }

    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupManagers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupManagers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationAction()
        setupMapContainer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapManager.viewWillAppear()
        tabBarController?.tabBar.isHidden = true
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 먼저 모든 Subject들 완료 처리하여 새로운 이벤트 방지
        mapPositionChangedRelay.onCompleted()
        estateTypeChangedRelay.onCompleted() 
        estateSelectedRelay.onCompleted()
        floatButtonTappedRelay.onCompleted()
        filterChangedRelay.onCompleted()
        
        mapManager.viewWillDisappear()
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Delegate 해제
        mapManager.delegate = nil
        filterManager.delegate = nil
        bottomCollectionManager.delegate = nil
        floatButton.onClick = nil
        
        // ViewModel 정리
        viewModel.cleanup()
        
        mapManager.viewDidDisappear()
        mapManager.cleanup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        filterManager.updateTooltipPositions()
        
        // Float Button이 맨 앞에 있도록 보장
        view.bringSubviewToFront(floatButton)
        
    }
    
    override func setupUI() {
        super.setupUI()
        setupBottomCollectionView()
        view.addSubviews(mapSearchView, mapNavigationBar, bottomCollectionView, floatButton)
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
        
        bottomCollectionView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(132)
        }
        
        // Float Button - 초기에는 우측 하단에 위치
        floatButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(48)
        }
    }
    
    /// - ViewModel 바인딩
    override func bind() {
        // Float Button 터치 이벤트 활성화 확인
        floatButton.isUserInteractionEnabled = true
        
        floatButton.onClick = { [weak self] in
            self?.floatButtonTappedRelay.onNext(())
        }
        
        let input = EstateMapViewModel.Input(
            mapPositionChanged: mapPositionChangedRelay.asObservable(),
            estateTypeChanged: estateTypeChangedRelay.asObservable(),
            estateSelected: estateSelectedRelay.asObservable(),
            floatButtonTapped: floatButtonTappedRelay.asObservable(),
            filterChanged: filterChangedRelay.asObservable(),
            loadAllEstates: .just(()).asObservable() // 앱 시작 시 즉시 전체 데이터 로드
        )
        
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .drive(onNext: { isLoading in
                // TODO: 로딩 UI 업데이트
            })
            .disposed(by: disposeBag)
        
        output.estates
            .drive(onNext: { [weak self] estates in
                // 전체 데이터가 로드되지 않은 경우에만 기존 방식 사용
                if !(self?.mapManager.isAllEstatesLoaded ?? false) {
                    // 임시로 기존 public 메서드명 사용 (나중에 internal로 변경)
                    // self?.mapManager.updateEstateMarkersInternal(with: estates)
                }
                
                // Update bottom collection view
                guard let self = self, let estateType = self.estateType else { return }
                let currentZoom = self.getCurrentZoomLevel()
                
                // 매물 데이터를 항상 업데이트
                if !estates.isEmpty {
                    self.bottomCollectionManager.updateEstates(estates, estateType: estateType)
                }
                
                // 줌 레벨 13 이상이거나 개별 마커 상태가 true이고 매물이 있으면 컬렉션뷰 표시
                let shouldShowCollection = !estates.isEmpty && (currentZoom >= 13 || self.isShowingIndividualMarkers)
                
                if shouldShowCollection {
                    self.bottomCollectionManager.showCollectionView()
                    self.updateFloatButtonPosition(collectionViewVisible: true)
                } else {
                    self.bottomCollectionManager.hideCollectionView()
                    self.updateFloatButtonPosition(collectionViewVisible: false)
                }
            })
            .disposed(by: disposeBag)
        
        output.selectedEstate
            .drive(onNext: { [weak self] estate in
                let detailVC = EstateDetailViewController(estate.estate_id)
                self?.navigationController?.pushViewController(detailVC, animated: true)

            })
            .disposed(by: disposeBag)
        
        output.currentLocation
            .drive(onNext: { [weak self] location in
                // TODO: 현재 위치로 지도 이동 또는 다른 액션 수행
                self?.handleCurrentLocation(latitude: location.latitude, longitude: location.longitude)
            })
            .disposed(by: disposeBag)
        
        output.error
            .drive(onNext: { error in
                // TODO: 에러 처리 UI
            })
            .disposed(by: disposeBag)
        
        output.allEstatesLoaded
            .drive(onNext: { [weak self] estates in
                self?.mapManager.loadAllEstates(estates)
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
    }
}
// MARK: - Private Methods
private extension EstateMapViewController {
    

    
    /// - 매니저들 설정
    func setupManagers() {
        mapManager.delegate = self
        filterManager.delegate = self
        bottomCollectionManager.delegate = self
    }
    
    /// - 하단 컬렉션뷰 설정
    func setupBottomCollectionView() {
        bottomCollectionView = bottomCollectionManager.setupCollectionView(in: view)
        bottomCollectionView.backgroundColor = .clear
        bottomCollectionView.layer.shadowColor = UIColor.black.cgColor
        bottomCollectionView.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomCollectionView.layer.shadowOpacity = 0.1
        bottomCollectionView.layer.shadowRadius = 4
        bottomCollectionView.isHidden = true // 초기에는 숨김
    }
    
    /// - 현재 줌 레벨 가져오기
    func getCurrentZoomLevel() -> Int {
        return mapManager.getCurrentZoomLevel()
    }
    
    /// - Float Button 위치 업데이트 (컬렉션뷰 상태에 따라)
    private func updateFloatButtonPosition(collectionViewVisible: Bool) {
        floatButton.snp.remakeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(48)
            
            if collectionViewVisible {
                // 컬렉션뷰가 보일 때: 컬렉션뷰 우측 상단
                $0.bottom.equalTo(bottomCollectionView.snp.top).offset(-12)
            } else {
                // 컬렉션뷰가 숨겨져 있을 때: 우측 하단
                $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            }
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// - 현재 위치 처리
    private func handleCurrentLocation(latitude: Double, longitude: Double) {
        
        // 지도를 현재 위치로 이동
        mapManager.moveToLocation(latitude: latitude, longitude: longitude)
        
        // 현재 위치 기준으로 매물 검색
        let maxDistance = mapManager.calculateMaxDistance(from: getCurrentZoomLevel())
        mapPositionChangedRelay.onNext((
            latitude: latitude,
            longitude: longitude,
            maxDistance: maxDistance
        ))
    }
    
    /// - 위치 권한 확인 후 현재 위치로 이동
    private func checkLocationPermissionAndMoveToCurrentLocation() {
        
        // LocationService에서 현재 권한 상태 확인
        let locationService = LocationService()
        let currentStatus = locationService.authorizationStatus
        
        switch currentStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 허용되어 있으면 잠시 후 현재 위치 가져오기 (지도 완전 초기화 대기)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.floatButtonTappedRelay.onNext(())
            }
            
        case .notDetermined:
            break
            
        case .denied, .restricted:
            break
            
        @unknown default:
            break
        }
    }
    
    /// - 네비게이션 액션 설정
    func setNavigationAction() {
        mapNavigationBar.backButtonTapped = {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    /// - 맵 컨테이너 설정
    func setupMapContainer() {
        guard let mapContainer = mapManager.setupMapContainer(in: view, below: mapSearchView) else {
            return
        }
        
        /// - 필터 버튼들을 맵 위에 설정
        filterManager.setupFilterButtons(in: view, below: mapSearchView)
        filterManager.bringFiltersToFront(in: view, mapContainer: mapContainer)
        
        /// - Collection view와 Float button을 맨 앞으로 가져오기
        view.bringSubviewToFront(bottomCollectionView)
        view.bringSubviewToFront(floatButton)
    }
}

// MARK: - EstateMapManagerDelegate
extension EstateMapViewController: EstateMapManagerDelegate {
    
    func mapDidFinishSetup() {
        
        // 지도 설정 완료 후 위치 권한 확인하여 자동으로 현재 위치 표시
        checkLocationPermissionAndMoveToCurrentLocation()
    }
    
    func mapDidFailSetup(error: String) {
        /// - 맵 설정 실패 시 사용자에게 알림 또는 재시도 로직 구현
    }
    
    func mapPositionChanged(latitude: Double, longitude: Double, maxDistance: Int) {
        mapPositionChangedRelay.onNext((latitude: latitude, longitude: longitude, maxDistance: maxDistance))
    }
    
    func estateMarkerTapped(estateId: String) {
        let detailVC = EstateDetailViewController(estateId)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func markerClusterTapped(markerCount: Int, centerPosition: MapPoint, estates: [EstateGeoLocationDataResponse]) {
        
        // 클러스터 탭 시 해당 매물들로 컬렉션뷰 표시
        guard let estateType = self.estateType else { return }
        bottomCollectionManager.updateEstates(estates, estateType: estateType)
        bottomCollectionManager.showCollectionView()
        updateFloatButtonPosition(collectionViewVisible: true)
    }
    
    func individualMarkersDisplayStateChanged(isDisplaying: Bool) {
        isShowingIndividualMarkers = isDisplaying
        
        // 상태 변경 시 컬렉션뷰 표시 여부 재평가
        // 현재 매물 데이터가 있다면 컬렉션뷰 상태를 업데이트
        if isDisplaying {
        } else {
            bottomCollectionManager.hideCollectionView()
            updateFloatButtonPosition(collectionViewVisible: false)
        }
    }
}

// MARK: - EstateMapFilterManagerDelegate
extension EstateMapViewController: EstateMapFilterManagerDelegate {
    
    func filterDidToggle(isActive: Bool) {
        /// - 필터 활성화/비활성화에 따른 추가 로직 구현
    }
    
    func filterValueDidChange() {
        let currentValues = filterManager.getCurrentFilterValues()
        
        /// - 필터 값 변경을 ViewModel에 전달하여 필터링된 매물 표시
        filterChangedRelay.onNext(currentValues)
    }
}

// MARK: - EstateMapBottomCollectionManagerDelegate
extension EstateMapViewController: EstateMapBottomCollectionManagerDelegate {
    
    func didSelectEstate(_ estate: EstateGeoLocationDataResponse) {
        estateSelectedRelay.onNext(estate)
    }
}
