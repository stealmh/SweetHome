//
//  EstateMapViewController.swift
//  SweetHome
//
//  Created by 김민호 on 8/5/25.
//

import UIKit
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
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapManager.viewWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapManager.viewDidDisappear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        filterManager.updateTooltipPositions()
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubviews(mapSearchView, mapNavigationBar)
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
    }
    
    deinit {
        mapManager.cleanup()
    }
}
// MARK: - Private Methods
private extension EstateMapViewController {
    
    /// - 매니저들 설정
    func setupManagers() {
        mapManager.delegate = self
        filterManager.delegate = self
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
            print("❌ Failed to setup map container")
            return
        }
        
        /// - 필터 버튼들을 맵 위에 설정
        filterManager.setupFilterButtons(in: view, below: mapSearchView)
        filterManager.bringFiltersToFront(in: view, mapContainer: mapContainer)
    }
}

// MARK: - EstateMapManagerDelegate
extension EstateMapViewController: EstateMapManagerDelegate {
    
    func mapDidFinishSetup() {
        print("🎯 Map setup finished - ready to use")
        /// - 맵 설정 완료 후 추가 작업이 필요한 경우 여기에 구현
    }
    
    func mapDidFailSetup(error: String) {
        print("❌ Map setup failed: \(error)")
        /// - 맵 설정 실패 시 사용자에게 알림 또는 재시도 로직 구현
    }
}

// MARK: - EstateMapFilterManagerDelegate
extension EstateMapViewController: EstateMapFilterManagerDelegate {
    
    func filterDidToggle(isActive: Bool) {
        print("🔄 Filter toggled - active: \(isActive)")
        /// - 필터 활성화/비활성화에 따른 추가 로직 구현
    }
    
    func filterValueDidChange() {
        let currentValues = filterManager.getCurrentFilterValues()
        print("📊 Filter values changed:")
        print("  - Area: \(String(describing: currentValues.area))")
        print("  - Monthly Price: \(String(describing: currentValues.priceMonth))")
        print("  - Deposit: \(String(describing: currentValues.price))")
        
        /// - 필터 값 변경에 따른 지도 데이터 업데이트 로직 구현
        /// - 예: API 호출, 지도 마커 필터링 등
    }
}
