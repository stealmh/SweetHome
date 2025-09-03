//
//  HomeViewController.swift
//  SweetHome
//
//  Created by 김민호 on 7/23/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class HomeViewController: BaseViewController, UICollectionViewDelegate {
    private let searchBar = SHSearchBar()
    
    // MARK: - Layout & DataSource
    private var layoutManager: HomeCollectionViewLayout!
    private var dataSourceManager: HomeCollectionViewDataSource!
    
    enum Section: Int, CaseIterable {
        case banner
        case recentSearchEstate
        case hotEstate
        case topic
    }
    
    enum Item: Hashable {
        case estate(Estate, uniqueID: String)
        case recentEstate(Estate, uniqueID: String)
        case hotEstate(Estate, uniqueID: String)
        case emptyRecentSearch
        case topic(EstateTopic)
    }
    
    private lazy var collectionView: UICollectionView = {
        layoutManager = HomeCollectionViewLayout(delegate: self)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layoutManager.createLayout())
        cv.isPagingEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.bounces = true
        cv.alwaysBounceVertical = false
        cv.alwaysBounceHorizontal = false
        cv.isScrollEnabled = true
        cv.register(BannerCollectionViewCell.self, forCellWithReuseIdentifier: BannerCollectionViewCell.identifier)
        cv.register(RecentSearchEstateViewCell.self, forCellWithReuseIdentifier: RecentSearchEstateViewCell.identifier)
        cv.register(HotEstateViewCell.self, forCellWithReuseIdentifier: HotEstateViewCell.identifier)
        cv.register(EmptyRecentSearchViewCell.self, forCellWithReuseIdentifier: EmptyRecentSearchViewCell.identifier)
        cv.register(BannerFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BannerFooterView.identifier)
        cv.register(EstateSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EstateSectionHeaderView.identifier)
        cv.register(EstateTopicViewCell.self, forCellWithReuseIdentifier: EstateTopicViewCell.identifier)
        
        dataSourceManager = HomeCollectionViewDataSource(collectionView: cv, delegate: self)
        return cv
    }()
    
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = SHColor.GrayScale.gray_15
        pc.pageIndicatorTintColor = SHColor.GrayScale.gray_60
        pc.numberOfPages = 0
        pc.currentPage = 0
        return pc
    }()
    
    private let viewModel = HomeViewModel()
    private var estates: [Estate] = []
    private var infiniteArray: [Estate] = []
    private var currentAutoScrollIndex = 1
    private var recentEstates: [Estate] = []
    private var hotEstates: [Estate] = []
    private var topics: [EstateTopic] = []
    private var isInitialLayoutSet = false
    private var isDataLoaded = false
    
    private let startAutoScrollSubject = PublishSubject<Void>()
    private let stopAutoScrollSubject = PublishSubject<Void>()
    private let userScrollingSubject = BehaviorSubject<Bool>(value: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewDelegate()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isInitialLayoutSet {
            isInitialLayoutSet = true
    
            collectionView.contentOffset = CGPoint(x: 0, y: 0)
            
            if isDataLoaded && !infiniteArray.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.currentAutoScrollIndex = 1
                    self.collectionView.scrollToItem(
                        at: IndexPath(item: 1, section: 0),
                        at: .left,
                        animated: false
                    )
                }
            }
        }
    }
    
    override func setupUI() {
        view.addSubviews(collectionView, searchBar, pageControl)
    }
    
    override func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalTo(view)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(getStatusBarHeight() + 3)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.top).offset(335 - 16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(6)
        }
    }
    
    private func setupCollectionViewDelegate() {
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    override func bind() {
        let input = HomeViewModel.Input(
            onAppear: .just(()),
            startAutoScroll: startAutoScrollSubject.asObservable(),
            stopAutoScroll: stopAutoScrollSubject.asObservable(),
            userScrolling: userScrollingSubject.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        // Loading state binding
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.collectionView.isHidden = true
                    self.showLoading()
                } else {
                    self.collectionView.isHidden = false
                    self.hideLoading()
                }
            })
            .disposed(by: disposeBag)
        
        // Error handling
        output.error
            .drive(onNext: { [weak self] error in
                self?.hideLoading()
                // TODO: 에러 처리 로직 추가
                print("Error occurred: \(error)")
            })
            .disposed(by: disposeBag)
        
        output.todayEstates
            .drive(onNext: { [weak self] estates in
                guard let self else { return }
                self.estates = estates
                self.infiniteArray = self.createInfiniteArray(estates)
                self.pageControl.numberOfPages = estates.count
                self.pageControl.currentPage = 0
                self.updateFullSnapshot()
                
                // 데이터가 있고 초기 레이아웃이 완료된 후에만 자동 스크롤 시작
                if !self.infiniteArray.isEmpty && !estates.isEmpty && !self.isDataLoaded {
                    self.isDataLoaded = true
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        // 초기 레이아웃이 완료된 후에만 스크롤 위치 이동
                        if self.isInitialLayoutSet {
                            self.currentAutoScrollIndex = 1
                            self.collectionView.scrollToItem(
                                at: IndexPath(item: 1, section: 0),
                                at: .left,
                                animated: false
                            )
                        }
                        self.startAutoScrollSubject.onNext(())
                    }
                }
            })
            .disposed(by: disposeBag)
        
        output.autoScrollTrigger
            .drive(onNext: { [weak self] _ in
                self?.moveToNextPage()
            })
            .disposed(by: disposeBag)
        
        output.recentSearchEstates
            .drive(onNext: { [weak self] estates in
                self?.recentEstates = estates
                self?.updateFullSnapshot()
            })
            .disposed(by: disposeBag)
        
        output.hotEstates
            .drive(onNext: { [weak self] estates in
                self?.hotEstates = estates
                self?.updateFullSnapshot()
            })
            .disposed(by: disposeBag)
        
        output.topics
            .drive(onNext: { [weak self] topics in
                self?.topics = topics
                self?.updateFullSnapshot()
            })
            .disposed(by: disposeBag)
        
        pageControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                self?.pageControlValueChanged()
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("HomeViewController deinit")
        // UICollectionView delegate 해제
        collectionView.delegate = nil
        
        // LayoutManager와 DataSource delegate 해제
        layoutManager?.delegate = nil
        dataSourceManager = nil
        layoutManager = nil
    }
}
// MARK: - Private Method
extension HomeViewController {
    func moveToNextPage() {
        guard !infiniteArray.isEmpty else { return }
        
        currentAutoScrollIndex += 1
        
        if currentAutoScrollIndex >= infiniteArray.count - 1 {
            currentAutoScrollIndex = 1
        }
        
        collectionView.scrollToItem(
            at: IndexPath(item: currentAutoScrollIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    func createInfiniteArray(_ items: [Estate]) -> [Estate] {
        guard !items.isEmpty else { return [] }
        
        var infiniteArray: [Estate] = []
        let count = items.count
        
        infiniteArray.append(items[count - 1])
        infiniteArray.append(contentsOf: items)
        infiniteArray.append(items[0])
        
        return infiniteArray
    }
    
    
    private func pageControlValueChanged() {
        userScrollingSubject.onNext(true)
        
        let targetPage = pageControl.currentPage
        let targetIndex = targetPage + 1
        
        if targetIndex < infiniteArray.count {
            currentAutoScrollIndex = targetIndex
            collectionView.scrollToItem(
                at: IndexPath(item: targetIndex, section: 0),
                at: .left,
                animated: true
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.userScrollingSubject.onNext(false)
        }
    }
    
    func updatePageControlFromOrthogonal(currentPage: Int) {
        guard !estates.isEmpty else { return }
        
        let actualPage: Int
        
        if currentPage == 0 {
            actualPage = estates.count - 1
        } else if currentPage <= estates.count {
            actualPage = currentPage - 1
        } else {
            actualPage = 0
        }
        
        pageControl.currentPage = actualPage
    }
    
    func updateFullSnapshot() {
        /// - 현재 스크롤 위치 저장
        let currentOffset = collectionView.contentOffset
        
        /// - 레이아웃 업데이트
        collectionView.setCollectionViewLayout(layoutManager.createLayout(), animated: false)
        
        /// - 스크롤 위치 복원 (초기 로드가 아닌 경우에만)
        if isInitialLayoutSet {
            collectionView.contentOffset = currentOffset
        }

        let bannerItems = infiniteArray.enumerated().map { index, estate in
            Item.estate(estate, uniqueID: "\(estate.id)_\(index)")
        }

        let recentItems: [Item]
        if recentEstates.isEmpty {
            recentItems = [.emptyRecentSearch]
        } else {
            recentItems = recentEstates.enumerated().map { index, estate in
                Item.recentEstate(estate, uniqueID: "\(estate.id)_recent_\(index)")
            }
        }
        
        let hotItems = hotEstates.enumerated().map { index, estate in
            Item.hotEstate(estate, uniqueID: "\(estate.id)_hot_\(index)")
        }
        
        let topicItems = topics.map { Item.topic($0) }
        
        dataSourceManager.updateSnapshot(
            bannerItems: bannerItems,
            recentItems: recentItems,
            hotItems: hotItems,
            topicItems: topicItems
        )
    }
}

// MARK: - HomeCollectionViewLayoutDelegate
extension HomeViewController: HomeCollectionViewLayoutDelegate {
    func handleBannerScrolling(items: [NSCollectionLayoutVisibleItem], contentOffset: CGPoint, environment: NSCollectionLayoutEnvironment) {
        let pageWidth = environment.container.contentSize.width
        let currentPage = Int(contentOffset.x / pageWidth)
        let currentOffset = contentOffset.x
        let progress = (currentOffset / pageWidth) - floor(currentOffset / pageWidth)
        
        if self.currentAutoScrollIndex != currentPage {
            self.userScrollingSubject.onNext(true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.userScrollingSubject.onNext(false)
            }
        }
        
        self.currentAutoScrollIndex = currentPage
        
        if currentPage == 0 && !self.infiniteArray.isEmpty && abs(progress) < 0.1 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let targetIndex = self.infiniteArray.count - 2
                self.currentAutoScrollIndex = targetIndex
                self.collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .left, animated: false)
            }
        } else if currentPage == self.infiniteArray.count - 1 && !self.infiniteArray.isEmpty && abs(progress) < 0.1 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.currentAutoScrollIndex = 1
                self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .left, animated: false)
            }
        }
        
        self.updatePageControlFromOrthogonal(currentPage: currentPage)
    }
    
    func isRecentEstatesEmpty() -> Bool {
        return recentEstates.isEmpty
    }
}

// MARK: - HomeCollectionViewDataSourceDelegate
extension HomeViewController: HomeCollectionViewDataSourceDelegate {
    /// - 최근검색 매물 전체보기 버튼 눌렀을 때
    func viewAllTapped() {
        // TODO: 최근 검색 매물 전체보기 로직 구현
        print("HOT 매물 전체보기 탭")
    }
    /// - 핫 매물 전체보기 버튼 눌렀을 때
    func hotEstateViewAllTapped() {
        // TODO: HOT 매물 전체보기 로직 구현
        print("HOT 매물 전체보기 탭")
    }
    /// - 배너 Footer의 카테고리 항목 눌렀을 때
    func bannerEstateTypeTapped(_ estateType: BannerEstateType) {
        let detailVC = EstateMapViewController()
        detailVC.estateType = estateType
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// - SearchBar와 pageControl 위치 설정
        let offsetY = scrollView.contentOffset.y
        
        let topLimit: CGFloat = -44
        let baseTop: CGFloat = getStatusBarHeight() + 3
        let adjustedTop = max(topLimit, baseTop - offsetY)
        
        searchBar.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(adjustedTop)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        let bannerBottomY: CGFloat = 335 - 16
        let pageControlY = max(0, bannerBottomY - offsetY)
        
        pageControl.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(pageControlY)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(6)
        }
        
        /// - ScrollView의 위치가 맨 위일 때는 스크롤 방지
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }
}

// MARK: - UICollectionViewDelegate Methods
extension HomeViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSourceManager.getItem(for: indexPath) else { return }
        
        switch item {
        /// - 상단 배너 눌렀을 때
        case .estate(let estate, _):
            let detailVC = EstateDetailViewController(estate.id)
            navigationController?.pushViewController(detailVC, animated: true)
        /// - 최근 검색 매물 눌렀을 때
        case .recentEstate(let estate, _):
            let detailVC = EstateDetailViewController(estate.id)
            navigationController?.pushViewController(detailVC, animated: true)
        /// - 핫 매물 눌렀을 때
        case .hotEstate(let estate, _):
            let detailVC = EstateDetailViewController(estate.id)
            navigationController?.pushViewController(detailVC, animated: true)
        /// - 토픽 눌렀을 때
        case .topic(let topic):
            if let linkString = topic.link,
               let url = URL(string: linkString) {
                let webViewController = WebViewController(url: url, title: topic.title)
                navigationController?.pushViewController(webViewController, animated: true)
            }
            
        case .emptyRecentSearch:
            break
        }
    }
}
